#!/bin/sh
# the next line restarts using wish \
exec wish "$0" "$@"

package require Tktable

#set tt(path) "V:/Terentjev/Work/WMS_New/WMS_Zond/WMS_TT"
set tt(src_path) "./src/tt"
set tt(conf_path) "./conf/tt"
catch [file mkdir $tt(conf_path)/smart_place]

source $tt(src_path)/wms_temp_define.tcl
source $tt(src_path)/wms_temp_driver.tcl
source $tt(src_path)/wms_temp_maketask.tcl
source $tt(src_path)/wms_temp_serv.tcl

#console show

set tt(opensock) 0
# Otkrytie soketa dlja vzaimodeystvija s drugimi programmami
socket -server on_connect 4442

wm protocol . WM_DELETE_WINDOW exitProg
wm geometry . "=300x400+200+100"

# Global defaults
#if { [file exists $tt(conf_path)/tt_[info hostname].def] } {
#  set fd [open $tt(conf_path)/tt_[info hostname].def r]
#  set lt [gets $fd]
#  close $fd
#  set config(dev) [lindex $lt 0]
#  set config(rate) [lindex $lt 1]
#  set config(canals) [lindex $lt 2]
#  set config(idir) [lindex $lt 3]
#  set config(debug) [lindex $lt 4]
#  set config(edit) [lindex $lt 5]
#} else {
#  set config(dev) "COM1"
#  set config(rate) 19200
#  set config(canals) $tt(conf_path)/tt_canals.def
#  set config(idir) $tt(conf_path)/temp
#  set config(debug) 1
#  set config(edit) 0
#}

#
# Smart placement
if { [file exists "$tt(conf_path)/smart_place/wms_temp_[info hostname].smp"] } {
  set f [open "$tt(conf_path)/smart_place/wms_temp_[info hostname].smp" "r"]
  while {![eof $f]} {
    set s [eval list [gets $f]]
    if {[llength $s]} {
      set w [lindex $s 0]
      if {[winfo exists $w]} {
       set g [lindex $s 1]
       wm geometry $w "=$g"
      }
    }
  }
  close $f
}

# прочитать описания каналов
define $tt(conf_path)/tt_canals.def

if {[llength $config(pars_name)]<16} {

  set row [llength $config(pars_name)]
  set cols 2
} else {

  set row 15
  set cols [expr {int((ceil([llength $config(pars_name)]/16)+1)*2)}]
}

labelframe .ftab -text "Table"
grid .ftab -row 0 -column 0 -sticky news

  table .ftab.t -rows $row -cols $cols -variable tbl -state disabled \
   -sparsearray 0 -selectmode extended
  grid .ftab.t -row 0 -column 0 -sticky news

  set i 0
  set j 0
  foreach name $config(pars_name) {

    set tbl($i,$j) $name
    incr i
    if {$i==15} {
      set i 0
      incr j 2
    }
  }

labelframe .fbut -text "Buttons"
grid .fbut -row 1 -column 0 -sticky news

  button .fbut.bt00 -width 10 -text "Scan" -command runScan
  grid .fbut.bt00 -row 0 -column 0 -sticky news
  button .fbut.bt01 -width 10 -text "Stop" -command stopScan
  grid .fbut.bt01 -row 0 -column 1 -sticky news
  button .fbut.bt02 -width 10 -text "Exit" -command exitProg
  grid .fbut.bt02 -row 0 -column 2 -sticky news
  label .fbut.lb10 -width 30 -textvar config(status)
  grid .fbut.lb10 -row 1 -column 0 -columnspan 3 -sticky news
  
  set config(status) "Idle"

proc runScan {} {
global config par
# Подготовка задания
  set ltask [makeTask]

# Открыли порт
  if {[catch {set fh [socket 192.168.0.124 4002]}]} {

     set answ [tk_messageBox -message "Нет связи с MOXA. Проверьте подключение устройства." -title "Error" -type ok -icon error]
  } else {
    fconfigure $fh -translation binary -eofchar {}

    set config(port) $fh

# Загрузка задания
    set cod [loadTask $ltask]

    set config(status) "Loaded"

# Запуск измерений
    set codr [runDev]

    set config(status) "Run"

    .fbut.bt01 configure -state normal
    .fbut.bt00 configure -state disabled

    after 200 processData
  }
}

proc stopScan {} {
global config

  set config(status) "Stop"
}

proc processData {} {
global config par value sens tt
global flck vlck  tbl

  set t1 [clock clicks -milliseconds]
  set codm [getData [llength $config(pars_name)] 0 ]
  for {set i 0} {$i<[llength $config(pars_name)]} {incr i} {
    set p $par($i,num)
    if { $par($i,fp) } {
      set value($i) [gorner $value($i) $sens($par($i,sens),a0) $sens($par($i,sens),a1) $sens($par($i,sens),a2) $sens($par($i,sens),a3)  ]
    }
  }
  
# Tables data and graph value text markers
  set i 0
  set j 1
  for {set p 0} {$p<[llength $config(pars_name)]} {incr p} {
    set tbl($i,$j) [formatVal $value($p) $p]
#    sendMes "$tbl($i,$j) $tbl($i,0)"
    incr i
    if {$i==15} {
      set i 0
      incr j 2
    }
  }

  if {$tt(opensock)} {
    foreach sock $tt(socket) {
      for {set indx 0} {$indx<[llength $config(pars_name)]} {incr indx} {
        set name [lindex $config(pars_name) $indx]
        if {$tt($sock,$name,meas)} {

          set val [format "%6.2f" $value($indx)]
          sendMes $sock "Meas done $name $tt($sock,$name,n) $val $tt($sock,$name,cnt)"
          if {$tt($sock,$name,cnt)<$tt($sock,$name,nmbcnt)} {
            incr tt($sock,$name,cnt)
          } else {

            set tt($sock,$name,meas) 0
          }
        }
      }
    }
  }

  set t2 [clock clicks -milliseconds]
  set dt [expr {1000 - ($t2 - $t1)}]

  if {$dt<0} {set dt 0}

  if {$config(status)=="Run"} {
    after $dt processData
  } elseif { $config(status)=="Stop"} {
# Останов измерений
    set cods [stopDev]

    close $config(port)
    set config(status) "Idle"

    .fbut.bt01 configure -state disabled
    .fbut.bt00 configure -state normal
  }
}

## Форматирование р-та измерений
proc formatVal {val p} {
  if {[string  match {*[0-9-.]} $val]} {
    if {[string equal "nan" $val]} { return 0. }
#    puts $val

    set aval [expr abs($val)]

    if { $aval<1. } {
      set fmt "%8.5f"
    } elseif { $aval<10. } {
      set fmt "%8.4f"
    } elseif { $aval<1000. } {
      set fmt "%8.3f"
    } elseif { $aval<100000. } {
      set fmt "%8.1f"
    } else {
      set fmt "%9.0f"
    }

    return [format $fmt $val]
  } else {
    return 0
  }
}

proc exitProg {} {
global config tt

  stopScan
  catch {close $config(port)}
# Save window positions for smart placement
  set f [open "$tt(conf_path)/smart_place/wms_temp_[info hostname].smp" "w"]
  set g [wm geometry .]
  puts $f ". $g"
  close $f
  exit
}

after 100 runScan