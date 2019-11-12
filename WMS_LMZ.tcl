#!/bin/sh
# the next line restarts using wish \
exec wish "$0" "$@"

## Ispol'zuemie paketi

if {[catch {package require -exact Iwidgets 4.0.2}]} {

  tk_messageBox -message "Для работы программы необходимо установить Iwidgets 4.0.2" -title "Error" -type ok -icon error
  exit
}
package require BWidget
package require BLT
  namespace import blt::*
package require Tktable
package require mysqltcl

## Ispol'zuemie fayli

source ./Top/wms_cfg.tcl
source ./Top/wms_proc.tcl
source ./Top/wms_Add_Point.tcl
source ./Top/wms_meas.tcl

source ./Top/wms_RF.tcl
source ./Top/wms_FF.tcl
source ./Top/wms_FF_Swms.tcl

source ./Top/wms_calc_disp.tcl

source ./Top/wms_clnt_TT.tcl
source ./Top/wms_clnt_Swms.tcl
source ./Top/wms_clnt_Adam.tcl

  wm title . "WMS_LMZ"
  wm geometry . "=+250+150"
  wm protocol . WM_DELETE_WINDOW ExitPr
  focus -force .
  bind . <F10> "ExitPr"

  set wms(active) 0
#  if {[info hostname]=="wmsn"} {set wms(sm) 1}

menu .menu -tearoff 0

set m .menu.file
menu $m -tearoff 0
.menu add cascade -label "Файл" -menu $m -underline 0
$m add command -label "Выход" -command ExitPr

set m .menu.init
menu $m -tearoff 0
.menu add cascade -label "Измер-е Коэф" -menu $m -underline 0
$m add command -label "Измер-е Коэф" -state disable -command "MeasCoef"
$m add command -label "Очистить графики" -command "ClearChart"


set m .menu.options
menu $m -tearoff 0
.menu add cascade -label "Опции" -menu $m -underline 0
$m add command -label "Настройки" -command Properties -state disable
$m add check -label Active -variable wms(active) -command ReadIni
$m add check -label "Измерение температуры" -variable wms(temp) -command "SaveProp; TTContr"
$m add check -label "Контроль свед/разв" -variable wms(zndjntctr) -command "SaveProp"
$m add check -label "Обработка" -variable wms(calculate)

. configure -menu .menu

set row1 0
set column 0

frame .fr1
pack .fr1 -side top -anchor w

set fr [frame .fr1.com]
grid $fr -row 0 -column 0 -sticky nw

set zond [frame .fr1.zond]
grid $zond -row 0 -column 1 -sticky nw

  labelframe $fr.mnlf -text "Имя Замера"
  grid $fr.mnlf -row $row1 -column $column  -sticky nw -pady 5
  incr row1

    ComboBox $fr.mnlf.cb -width 10 -textvariable wms(mn) -values $wms(mnlist) -justify right
    pack $fr.mnlf.cb

  labelframe $fr.daelf -text "Имя Режима"
  grid $fr.daelf -row $row1 -column $column -sticky nw -pady 5

    label $fr.daelf.lb -width 10 -textvariable wms(dae) -justify right
    pack $fr.daelf.lb
    
  incr row1

  labelframe $fr.zondlf -text "Зонды"
  grid $fr.zondlf -row $row1 -column $column -sticky nw -pady 5
  
  set row2 0

  foreach name {S01 S02} {

    label $fr.zondlf.lb$name -width 10 -text $name -justify right
    grid $fr.zondlf.lb$name -row $row2 -column 0 -sticky nw

    checkbutton $fr.zondlf.cb$name -variable wms($name,active) -justify right -anchor ne -command "SetConfZond $name"
    grid  $fr.zondlf.cb$name -row $row2 -column 1 -sticky nw
    incr row2
  }
  incr row1

  labelframe $fr.startlf -text "Запуск замера"
  grid $fr.startlf -row $row1 -column $column -sticky nw -pady 5
  
  button $fr.startlf.bt1 -text "Старт" -width 10 -command "StartMeas" -state disable
  label $fr.startlf.lb -textvar wms(mpoint)
  pack $fr.startlf.bt1 $fr.startlf.lb  -side top

set dat [frame .fr2]
pack .fr2 -side bottom -anchor w

  set dt [frame $dat.dt]
  set clck [frame $dat.clck]
  grid $dt -row 0 -column 0 -sticky news
  grid $clck -row 0 -column 1 -sticky news

## Sozdanie polja dati

  label $dt.dtn -width 7 -text "Дата:"
  label $dt.dt -width 9 -textvariable wms(dt)
  pack $dt.dtn $dt.dt -side left

## Sozdanie polja vremeni

  label $clck.clckn -width 7 -text "Время:"
  label $clck.clck -width 7 -textvariable wms(clck)
  pack $clck.clckn $clck.clck -side left

# Zapusk procedur obnovlenija dati i vremeni

  if { [file exists "Data/Config/[info hostname].ini"] } {

    set of [open "Data/Config/[info hostname].ini" "r"]
    set data [read $of]
    close $of

    set lines [split $data \n]

    foreach str $lines {

      set s [eval list $str]
      if {[llength $s]} {

        set w [lindex $s 0]
        if {[winfo exists $w]} {

          set g [lindex $s 1]
          set gspl [split $g x+]
          set x [lindex $gspl 2]
          set y [lindex $gspl 3]
          wm geometry $w "+$x+$y"
        }
      }
    }
  }
  focus .

ReadIni
FindMeasDate

Clocks
Data

TTContr
#if {$wms(sm)} {runsm}
