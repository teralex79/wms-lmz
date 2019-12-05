## Функции рассчета r32 и влажности по измеренным данным.

### Так же графический интерфейс и доп. процедуры для возможности постобработки, путем выбора файла или папки с файлами с измеренными данными.
### Для запуска режима постобработки файл запускается с аргументом, напр. "1" (Уже не актуально, можно запускать без аргументов)

if {$argc>0 || ([info exists ::argv0] && $::argv0 eq [info script])} {
  set wms(top) 1
  set wms(unimod) 1
  console show
} else {
  set wms(top) 0
  set wms(dd) 0
  set wms(dd,flag) 0
}

if {$wms(top)} {
  #!/bin/sh
  # the next line restarts using wish \
  exec wish "$0" "$@"

  package require BWidget
  package require BLT
    namespace import blt::*

  wm geometry . "=+300+150"

  foreach name {S01 S02 S04 S05 S07} {
    set wms($name,l,uv) 250000
    set wms($name,l,ir) 930000
    set wms($name,npoints) 100
    set wms($name,corIo) 0
    set wms($name,2w,blu) 420000
    set wms($name,2w,red) 660000
  }

  set wms(S01,RWI) 589
  set wms(S02,RWI) 589
  set wms(S04,RWI) 739.4
  set wms(S05,RWI) 702.5
  set wms(S07,RWI) 700.5

  set wms(S01,RTI) 568
  set wms(S02,RTI) 568
  set wms(S04,RTI) 705
  set wms(S05,RTI) 669
  set wms(S07,RTI) 669

  set wms(S01,RC) 364
  set wms(S02,RC) 364
  set wms(S04,RC) 455
  set wms(S05,RC) 617
  set wms(S07,RC) 617

  set wms(S01,RH) 271
  set wms(S02,RH) 271
  set wms(S04,RH) 273
  set wms(S05,RH) 270
  set wms(S07,RH) 270

  set wms(S01,ALFAI) -5
  set wms(S02,ALFAI) -5
  set wms(S04,ALFAI) -39
  set wms(S05,ALFAI) -28
  set wms(S07,ALFAI) -45

  set wms(tolerance) 5
  set wms(calibr) 7

  frame .fr
  pack .fr

  button .fr.bt -text "OpenFile" -width 10 -command FileDialog
  grid .fr.bt -row 0 -column 0
  button .fr.bt2 -text "OpenDir" -width 10 -command DirDialog
  grid .fr.bt2 -row 1 -column 0
  menu .menu -tearoff 0

  set m .menu.file
  menu $m -tearoff 0
  .menu add cascade -label "Файл" -menu $m -underline 0
  $m add command -label "Выход" -command exit

  set m .menu.options
  menu $m -tearoff 0
  .menu add cascade -label "Опции" -menu $m -underline 0
  $m add check -label Unimod -variable wms(unimod)

  . configure -menu .menu
}

proc FileDialog {} {
global calc wms

## Predvaritel'noe zadanie puti k konfiguratsionnomu faylu

  set wms(dd) 0
  set wms(dd,flag) 0

  .fr.bt configure -state disable
  .fr.bt2 configure -state disable
  set w "./Data"
  
  if {![catch {open [info hostname]_unimod.ini} of]} {
    set data [read $of]
    close $of

    set lines [split $data \n]
    foreach str $lines {
      set str [eval list $str]
      set [lindex $str 0] [lindex $str 1]
    }
  }
  
  if {[info exists calc(initialdir)]} {
    set w $calc(initialdir)
  }

## Opisanie tipov otobrazhaemih faylov

  set types {

    {"Data files" {.txt}}
    {"All files" *}
  }

  set infile ""


## Operatsia otkritija fayla

  set file [tk_getOpenFile -initialfile $infile -filetypes $types -parent . -initialdir $w]
  OpenFile $file
}

proc DirDialog {} {
global wms
## Predvaritel'noe zadanie puti k konfiguratsionnomu faylu

  .fr.bt configure -state disable
  .fr.bt2 configure -state disable

  set wms(dd) 1
  set wms(dd,flag) 0
  set fl(all) {}
  set w "."

  if {![catch {open [info hostname]_unimod.ini} of]} {
    set data [read $of]
    close $of

    set lines [split $data \n]
    foreach str $lines {
      set str [eval list $str]
      set [lindex $str 0] [lindex $str 1]
    }
  }

  if {![catch {open [info hostname]_ff.ini} of]} {
    set data [read $of]
    close $of

    set lines [split $data \n]
    foreach str $lines {
      set str [eval list $str]
      set [lindex $str 0] [lindex $str 1]
    }
  }

  if {[info exists initialdir]} {
    set w $initialdir
  }

## Operatsia otkritija fayla

  set dir [tk_chooseDirectory -initialdir $w -title "Choose a directory"]

  if {[llength $dir]} {
## Sohranenie poslednego vvedennogo puti

    set of [open [info hostname]_ff.ini w]
    puts $of "initialdir $dir"
    close $of
  } else {

    .fr.bt configure -state active
    .fr.bt2 configure -state active
  }
  set flist {}
  set b [glob -nocomplain -directory "$dir" -type d *]
  foreach item [eval list $b] {
    set c [glob -nocomplain -directory "$item" -type d *]
    foreach item2 [eval list $c] {
      set a [glob -nocomplain -directory "$item2" -type f *{wms.txt}*]
      lappend flist $a
    }
  }
  set nmb [llength [eval list $flist]]
  foreach fl2 [eval list $flist] {
    .fr.bt2 configure -text $nmb
    update
    set nmb [expr {$nmb-1}]
    OpenFile $fl2
  }
}

proc OpenFile {file} {
global calc wms

  if {[llength $file]} {
## Sohranenie poslednego vvedennogo puti

    .fr.bt configure -state disable
    .fr.bt2 configure -state disable

    set path [split [lindex $file 0] "\\/"]
    set path2 ""
    for {set i 0} {$i<[expr {[llength $path]-1}]} {incr i} {
      set path2 "${path2}[lindex $path $i]/"
    }
    set path2 "[string range ${path2} 0 end-1]"

    set calc(initialdir) $path2
    set name [lindex [split [lindex $path end] "_."] 0]
    set wms($name,type) [lindex [split [lindex $path end] "_."] 1]

    set cnt 0
    foreach nm {S01 S02 S04 S05 S07} {
      if {$nm==$name} {incr cnt}
    }
    foreach type {swms nwms test txt} {
      if {$type==$wms($name,type)} {incr cnt}
    }
    if {$cnt==2} {
      set of [open [info hostname]_unimod.ini w]
      puts $of "calc(initialdir) $path2"
      foreach nm {S01 S02 S04 S05 S07} {
        puts $of "wms($nm,l,uv)    $wms($nm,l,uv)   "
        puts $of "wms($nm,l,ir)    $wms($nm,l,ir)   "
        puts $of "wms($nm,npoints) $wms($nm,npoints)"
      }
      close $of
      FormOldWMS $name $path2
      if {$wms(unimod)} {ReadRAW_Disp $name $path2}
      if {$wms(top)} {
        .fr.bt configure -state active -text "OpenFile"
        .fr.bt2 configure -state active -text "OpenDir"
      }
    } else {
      .fr.bt configure -state active
      .fr.bt2 configure -state active
    }
  } else {
    .fr.bt configure -state active
    .fr.bt2 configure -state active
  }
}

proc ReadK2 {} {
global calc

# Read K/ro**2

  set calc(ro)  {}
  set calc(hk33) {}
  set calc(hk41) {}

#Find current path
  set Current_Dir [pwd]

# Replace (in the Current_Dir in variable Current_Dir) every instance of "/Top" which is a word by itself with "" (actualy remove "/Top" if exist):
  regsub -all {\/Top} $Current_Dir "" Current_Dir

  set file "${Current_Dir}/Data/Config/K2.txt"
  set of [open $file]
  set data [read $of]
  close $of

  set lines [split $data \n]
  foreach str $lines {
    if {[llength $str]>0} {

      set str [eval list $str]

      lappend calc(ro)  [lindex $str 1]
      lappend calc(hk33) [lindex $str 2]
      lappend calc(hk41) [lindex $str 3]
    }
  }
}

proc ChooseRange {name} {
global calc wms

  foreach nm {S01 S02 S04 S05 S07} {
    catch {destroy .grph$nm}
  }

  toplevel .grph$name
  wm geometry .grph$name "=+150+600"
  wm title .grph$name "Graph_$name"

  set tnb [blt::tabnotebook .grph$name.nb -takefocus 1 -samewidth no]
  pack $tnb -expand yes -fill both
  set tab 0
#Creating window with charts
  foreach tb {I_Io Spec2 Calc} {
    catch {$tnb delete $tab; destroy $tnb.c${name}}
    switch $tb {

      "Spec2" {

       $tnb insert $tab -text "$tb" -selectbackground RoyalBlue2

        set c [canvas $tnb.c${name}$tb -width 570 -height 300 -bg grey -highlightbackground  grey]
        pack $c
        $tnb tab configure $tab -window $c -anchor nw -fill both

        graph $c.sc -width 560 -height 300 -plotpadx {0 0} -plotpady {0 0} -plotbackground grey\
                         -fg black -bg grey
        $c create window 10 10 -window $c.sc -anchor nw

          global x${name}$tb y${name}$tb x${name}${tb}2 y${name}${tb}2

          vector create x${name}$tb y${name}$tb x${name}${tb}2 y${name}${tb}2

          x${name}Spec2 set {}
          y${name}Spec2 set {}
          x${name}Spec22 set {}
          y${name}Spec22 set {}

          $c.sc xaxis configure -title "l,nm" -min 200000 -max 1000000 -color black

          $c.sc grid configure -hide no -dashes {2 2} -color black

          $c.sc yaxis configure -title "I" -min 0 -titlecolor red -color red -justify right -rotate 90

          $c.sc element create "I" -ydata y${name}$tb -xdata  x${name}$tb\
           -label "" -mapy y -fill red -outline red -color red -pixels 0  -linewidth 2
          $c.sc element create "I2" -ydata y${name}${tb}2 -xdata  x${name}${tb}2\
           -label "" -mapy y -fill blue -outline blue -color blue -pixels 2  -linewidth 0
      }

      "I_Io" {

       $tnb insert $tab -text "$tb" -selectbackground RoyalBlue2

        set c [canvas $tnb.c${name}$tb -width 570 -height 300 -bg grey -highlightbackground  grey]
        pack $c
        $tnb tab configure $tab -window $c -anchor nw -fill both

        graph $c.sc -width 480 -height 300 -plotpadx {0 0} -plotpady {0 0} -plotbackground grey\
                         -fg black -bg grey
        $c create window 90 10 -window $c.sc -anchor nw

          global x${name}$tb y${name}$tb

          vector create x${name}$tb y${name}$tb

          x${name}$tb set {}
          y${name}$tb set {}

          $c.sc xaxis configure -title "l,nm" -min 200000 -max 1000000 -color black

          $c.sc grid configure -hide no -dashes {2 2} -color black

          $c.sc yaxis configure -title "IIo" -min 0 -titlecolor black -color black -justify right -rotate 90

          $c.sc element create "I_Io(630)" -ydata y${name}$tb -xdata  x${name}$tb\
           -label "" -mapy y -fill red -symbol diamond -outline red -color red -pixels 3  -linewidth 0
      }
      "Calc" {

       $tnb insert $tab -text "$tb" -selectbackground RoyalBlue2

        set c [canvas $tnb.c${name}$tb -width 570 -height 300 -bg grey -highlightbackground  grey]
        pack $c
        $tnb tab configure $tab -window $c -anchor nw -fill both

        graph $c.sc -width 560 -height 300 -plotpadx {0 0} -plotpady {0 0} -plotbackground grey\
                         -fg black -bg grey
        $c create window 10 10 -window $c.sc -anchor nw

        global x${name} y${name}temp y${name}C y${name}Cm y${name}X y${name}r y${name}rm

        vector create x${name} y${name}temp y${name}C y${name}Cm y${name}X y${name}r y${name}rm

        $c.sc grid configure -hide no -dashes {2 2} -color black

        $c.sc yaxis configure -title    "T" -titlecolor  white -color  white -justify right -rotate 90  -min 0
        $c.sc axis create p3  -title    "X" -titlecolor yellow -color yellow -justify  left -rotate 270 -min 0
        $c.sc axis create p4  -title    "r" -titlecolor green4 -color green4 -justify  left -rotate 270 -min 0
        $c.sc axis create p5  -title    "C" -titlecolor  black -color  black -justify  left -rotate 270 -min 0

        $c.sc element create "T" -ydata y${name}temp -xdata  x${name}\
          -symbol cross -mapy y -fill white -outline white -color grey -pixels 5  -linewidth 0

        $c.sc element create "C2" -ydata y${name}C -xdata  x${name}\
          -symbol cross -mapy p5 -color black  -pixels 5  -linewidth 0

        $c.sc element create "Cm" -ydata y${name}Cm -xdata  x${name}\
          -symbol cross -mapy p5 -color red3  -pixels 5  -linewidth 0

        $c.sc element create "X" -ydata y${name}X -xdata  x${name}\
          -symbol cross -mapy p3 -color yellow  -pixels 5  -linewidth 0

        $c.sc element create "r2" -ydata y${name}r -xdata  x${name}\
          -symbol cross -mapy p4 -color green4  -pixels 5 -linewidth 0

        $c.sc element create "rm" -ydata y${name}rm -xdata  x${name}\
          -symbol cross -mapy p4 -color green  -pixels 5 -linewidth 0

        $c.sc yaxis use {y p3}
        $c.sc y2axis use {p4 p5}
      }
    }
    incr tab
  }
#Creating window with parametrs for calculation
  if {!$wms(dd)} {
    toplevel .param
    wm title .param "Parameters"
    set chtp [labelframe .param.lb1  -text "Parameters" -font {TimesNewRoman 10} -labelanchor n]
    pack $chtp

    label $chtp.00 -width 10 -text "l_min"
    grid  $chtp.00 -row 0 -column 0 -sticky news
    label $chtp.01 -width 10 -text "l_max"
    grid  $chtp.01 -row 0 -column 1 -sticky news
    label $chtp.02 -width 10 -text "Points"
    grid  $chtp.02 -row 0 -column 2 -sticky news
    label $chtp.03 -width 15 -text "correct Io, %"
    grid  $chtp.03 -row 0 -column 3 -sticky news

    ComboBox $chtp.10 -width 10 -textvariable wms($name,l,uv) -values [lrange $calc($name,lamda) 4 end-6]
    grid  $chtp.10 -row 1 -column 0 -sticky news
    ComboBox $chtp.11 -width 10 -textvariable wms($name,l,ir) -values [lrange $calc($name,lamda) 4 end-6]
    grid  $chtp.11 -row 1 -column 1 -sticky news
    entry $chtp.12 -width 10 -textvar wms($name,npoints)
    grid  $chtp.12 -row 1 -column 2 -sticky news
    entry $chtp.13 -width 10 -textvar wms($name,corIo)
    grid  $chtp.13 -row 1 -column 3 -sticky news

    button $chtp.20 -text "Start" -command {
      global a
      set off [open [info hostname]_unimod.ini w]
      puts $off "calc(initialdir) $calc(initialdir)"
      foreach name {S01 S02 S04 S05 S07} {
        puts $off "wms($name,l,uv)    $wms($name,l,uv)   "
        puts $off "wms($name,l,ir)    $wms($name,l,ir)   "
        puts $off "wms($name,npoints) $wms($name,npoints)"
      }
      close $off

      set a 1
      destroy .param
    }
    grid   $chtp.20 -row 2 -column 0 -columnspan 4 -sticky news

    vwait a
  }
}

# Reading RAW file
proc ReadRAW_Disp {name file} {
global calc wms

  if {$wms($name,type)=="txt"} {
    set fn ${name}
  } else {
    set fn ${name}_$wms($name,type)
  }
  set of [open "$file/${fn}.txt"]
  set data [read $of]
  close $of

  set lines [split $data \n]

  set line 0
  set pnt  0
  set cnt3 0
  set flag 0
  set New_method 0
  set pi [expr {acos(-1)}]

  set calc($name,tr) {}
  set calc($name,new_meth) 0
  set calc($name,coord_in_tube) 2

  foreach str $lines {
    if {[llength $str]>0} {
      if {!$flag} {

## Read coefficients and initial parameters
        if {$line==0} {
          set s [split $str " :;"]
          if {$wms($name,type)=="txt"} {set wms($name,type) [lindex $s end-1]}

          set calc($name,dae) [lindex $s 6]
          set calc($name,mn)  [lindex $s 10]
          set calc($name,Io,cntlist) {}
          set calc($name,coef) {}
          set calc($name,2w,blu) $wms($name,2w,blu)
          set calc($name,2w,red) $wms($name,2w,red)
        }
        if {[lsearch $str "Join=*"]!=-1} {
          set b [lindex [split [lindex $str 0] =] 1]
          set calc($name,Io1) [string range $b 0 0]
          set calc($name,Io2) [string range $b end end]
        }
        if {[lsearch $str "NewMeth=*"]!=-1} {
          set b [lindex [split [lindex $str 0] =] 1]
          set calc($name,new_meth) [string range $b 0 0]
        }
        if {[lsearch $str "XinTube=*"]!=-1} {
          set b [lindex [split [lindex $str 0] =] 1]
          set calc($name,coord_in_tube) [string range $b 0 0]
        }
        if {[lsearch $str "L(мм)=*"]!=-1} {
          set b [split $str ";"]
          set d [split [lindex $b 1] =]
          set calc($name,L) [lindex $d 1]
        }
        if {[lsearch $str "RWI*"]!=-1} {
          set b [split $str ";"]
          foreach item $b {
            set item [eval list $item]
            set d [split $item =]
            set p1 [lindex $d 0]
            set p2 [lindex $d 1]
            if {$p1=="blu" || $p1=="red"} {
              set calc($name,2w,$p1) $p2
            } else {
              set calc($name,$p1) $p2
            }
          }
        }
        if {[lsearch $str "K(*"]!=-1} {
          set k [split $str ";"]
          foreach item $k {
            if {[llength $item]>0} {
              set kk [split $item "=()"]
              lappend calc($name,coef) [lindex $kk 3]
            }
          }
        }
        if {[lindex $str 0]=="hh:mm:ss"} {
          set flag 1
          set indxN [lsearch $str "N*"]
          set indxX [lsearch $str "X*"]
          set indxY [lsearch $str "Y*"]
          set indxD [lsearch $str "Dens*"]
          set indxJ [lsearch $str "Join*"]
          set indxType [lsearch $str "Type*"]
          set indxT [lsearch $str "T,**"]
          set strtindx [expr {[lsearch $str "T,*"]+1}]
          set calc($name,lamda) [lrange $str $strtindx end]
          set calc($name,s)  {}
          foreach lamda $calc($name,lamda) {
            lappend calc($name,s) [expr {(2.0*$pi)*pow(10,6)/$lamda}]
          }

          set min 0
          set max [expr {[llength $calc($name,lamda)-1]}]

          if {$wms($name,type)=="swms" || $wms($name,type)=="test"} {
            if {$wms(top)} {
## If calculation is executed as separate program then additional windows with charts and limitation and correction parameters open
              ChooseRange $name
            }
            update
# Limit the spectrum by lamda start
            set cnt4 0
            set flag2 0
# Fix indexes for min and max lamda
            foreach item $calc($name,lamda) {
              if {$flag2==0 && $item>=$wms($name,l,uv)} {
     #uv
                 set min $cnt4
                 incr flag2
              } elseif {$flag2==1 && $item>=$wms($name,l,ir)} {
     #ir
                 set max $cnt4
                 incr flag2
              } elseif {$flag2==2} {
                break
              }
              incr cnt4
            }
          }

## Add points for averaging
          if {$wms($name,type)=="swms" || $wms($name,type)=="test"} {
            set calc(aver) 11
            set min [expr {$min-$calc(aver)}]
            set max [expr {$max+$calc(aver)}]
            set aver $calc(aver)
          } else {
            set calc(aver) 1
            set aver 0
          }

# Limit spectrum
          set calc($name,coef,cut)  [lrange $calc($name,coef)  $min $max]
          set calc($name,lamda,cut) [lrange $calc($name,lamda) $min $max]
          set calc($name,s,cut)     [lrange $calc($name,s)     $min $max]

# Cut an overload peak from the spectrum
          if {$wms($name,type)=="swms"} {
            set cnt4 0
            set flag2 0
            set lrep1 no
            set lrep2 no
            foreach item $calc($name,lamda,cut) {
              if {$flag2==0 && $item>=644000} {
     #uv
                 set lrep1 $cnt4
                 incr flag2
              } elseif {$flag2==1 && $item>=656500} {
     #ir
                 set lrep2 $cnt4
                 incr flag2
              } elseif {$flag2==2} {
                break
              }
              incr cnt4
            }
            if {$lrep1!="no" && $lrep2!="no"} {
              set calc($name,coef,cut)  [lreplace $calc($name,coef,cut)  $lrep1 $lrep2]
              set calc($name,lamda,cut) [lreplace $calc($name,lamda,cut) $lrep1 $lrep2]
              set calc($name,s,cut)     [lreplace $calc($name,s,cut)     $lrep1 $lrep2]
            }
          }
# Reduce number of points for calculating
          set step [format "%2.0f" [expr {1.*([llength $calc($name,lamda,cut)] - $aver - 1)/$wms($name,npoints)}]]
          if {$step<1} {set step 1}
          set cut {}
          for {set i $aver} {$i<[expr {[llength $calc($name,lamda,cut)] - $aver - 1}]} {incr i $step} {
            lappend cut [expr {int($i)}]
          }

          lappend cut [expr {[llength $calc($name,lamda,cut)] - $aver - 1}]
          set calc($name,lamda,cutnmb) $cut
          set cnt4 0
          set flag2 0
          set flag3 0
          set calc($name,red,index) -1
          set calc($name,blu,index) -1

# Find indexes of the nearest blue and red wavelengths for old 2-wave method
          if {[llength $calc($name,lamda,cutnmb)]<11} {
            set d 40000
          } elseif {[llength $calc($name,lamda,cutnmb)]<200} {
            set d 3500
          } else {
            set d 500
          }
          set minblu [expr {$calc($name,2w,blu) - $d}]
          set maxblu [expr {$calc($name,2w,blu) + $d}]
          set minred [expr {$calc($name,2w,red) - $d}]
          set maxred [expr {$calc($name,2w,red) + $d}]

          foreach item $calc($name,lamda,cut) {
            if {$item>=$minblu && $item<=$maxblu} {
               set calc($name,blu,index) $cnt4
               set calc(oldblu) $item
               incr flag2
            } elseif {$item>$minred && $item<$maxred} {
               set calc($name,red,index) $cnt4
               set calc(oldred) $item
               incr flag3
            } elseif {$flag2 && $flag3} {
              break
            }
            incr cnt4
          }
          set calc(old) 1
          if {![info exists calc(oldred)]} {
            set calc(old) 0
            set calc(oldred) red
          }

          if {![info exists calc(oldblu)]} {

            set calc(old) 0
            set calc(oldblu) blu
          }
        }
        incr line
      } else {
#Read Data

#Calculate the number of rows for one measurement point depending on the method
        if {$cnt3==[expr {3+3*$calc($name,Io1)+3*$calc($name,Io2)}]} {
          incr pnt
          set cnt3 0
        }

        if {$cnt3==0} {
#If it is first string of meas point set its parameters
          set calc($name,time,$pnt) [lindex $str 0]
          set calc($name,N,$pnt)    [lindex $str $indxN]
          set calc($name,X,$pnt)    [lindex $str $indxX]
          set calc($name,Y,$pnt)    [lindex $str $indxY]
          set calc($name,Dens,$pnt) [lindex $str $indxD]
          set calc($name,T,$pnt)    [lindex $str $indxT]

          lappend calc($name,tr) $calc($name,X,$pnt)
#
          if {$calc($name,X,$pnt)<$wms($name,coord_in_tube)} {lappend calc($name,Io,cntlist) $pnt}
        }
        set Join [lindex $str $indxJ]
        set Type [lindex $str $indxType]
        set I_lst [lrange $str $strtindx end]

        if {$Type=="Iразв"} {
          set calc($name,wet,$pnt) 1
          if {[lindex $I_lst 0]==1 || [lindex $I_lst 0]==0} {set calc($name,wet,$pnt) 0}
          if {[info exists wms($name,wet,[expr {$pnt+1}])]} {
            set calc($name,wet,$pnt) $wms($name,wet,[expr {$pnt+1}])
          } else {
            set wms($name,wet,[expr {$pnt+1}]) $calc($name,wet,$pnt)
          }
        }
        set calc($name,$Type,$Join,$pnt) $I_lst
        set Bcur 0
        if {$wms($name,type)=="swms"} {
          foreach i {0 1 2 3 end-5 end-4 end-3 end-2 end-1 end} {
            set Bcur [expr {$Bcur+[lindex $I_lst $i]}]
          }
          set Bcur [expr {$Bcur/10.}]
          set IB_lst {}
          foreach item $I_lst {
            lappend IB_lst [expr {$item - $Bcur}]
          }
        } else {
          set IB_lst $I_lst
        }
        set calc($name,$Type,$Join,$pnt) $IB_lst
        set calc($name,$Type,$Join,$pnt,cut) [lrange $IB_lst $min $max]
        if {$wms($name,type)=="swms"} {
          if {$lrep1!="no" && $lrep2!="no"} {
            set calc($name,$Type,$Join,$pnt,cut)  [lreplace $calc($name,$Type,$Join,$pnt,cut)  $lrep1 $lrep2]
          }
        }
        incr cnt3
      }
    }
  }

  if {$wms(top) && $wms($name,type)=="swms"} {.grph$name.nb.c${name}Calc.sc xaxis configure -title "" -min 0 -max [expr {ceil([lindex [lsort -real $calc($name,tr)] end]/10.)*10}] -color black}

  set calc($name,points) $pnt
## Calculate Io
  if {$calc($name,new_meth)} {
    set i 0
    set calc($name,Io) {}
    catch {global x${name}Spec2 y${name}Spec2}
    foreach lamda $calc($name,lamda) {
      set Io 0
      foreach pnt_Io $calc($name,Io,cntlist) {
        set a4 [expr {1.*([lindex $calc($name,Iсв1,1,$pnt_Io) $i] - [lindex $calc($name,Bcur,1,$pnt_Io) $i])}]
        if {$a4<0} {set a4 0}
        set Ref [lindex $calc($name,Ref,1,$pnt_Io) $i]
        if {$Ref!=0} {set a4 [expr {1.*$a4/$Ref}]}
        set Io1 $a4
        if {!$calc($name,Io2)} {
          set Io2 $Io1
        } else {
          set a5 [expr {1.*([lindex $calc($name,Iсв2,2,$pnt_Io) $i] - [lindex $calc($name,Bcur,2,$pnt_Io) $i])}]
          if {$a5<0} {set a5 0}
          set Ref [lindex $calc($name,Ref,2,$pnt_Io) $i]
          if {$Ref!=0} {set a5 [expr {1.*$a5/$Ref}]}
          set Io2 $a5
        }

        set Io [expr {$Io + 1.*[lindex $calc($name,coef) $i]*($Io1 + $Io2)/2.}]
      }
      lappend calc($name,Io) [expr {(1.+$wms($name,corIo)/100.)*$Io/[llength $calc($name,Io,cntlist)]}]
      incr i

      set x${name}Spec2(++end) $lamda
      set y${name}Spec2(++end) [lindex $calc($name,Io) end]
    }
    set calc($name,Io,cut) [lrange $calc($name,Io) $min $max]
    if {$wms($name,type)=="swms"} {
      if {$lrep1!="no" && $lrep2!="no"} {
        set calc($name,Io,cut)  [lreplace $calc($name,Io,cut)  $lrep1 $lrep2]
      }
    }
  } elseif {$calc($name,Io1) || $calc($name,Io2)} {
    for {set pnt 0} {$pnt<=$calc($name,points)} {incr pnt} {
      set calc($name,Io,$pnt) {}
      set i 0
      foreach lamda $calc($name,lamda) {
        if {!$calc($name,Io1)} {
          set Io1 0
        } else {
          set a4 [expr {1.*([lindex $calc($name,Iсв1,1,$pnt) $i] - [lindex $calc($name,Bcur,1,$pnt) $i])}]
          if {$a4<0} {set a4 0}
          set Ref [lindex $calc($name,Ref,1,$pnt) $i]
          if {$Ref!=0} {set a4 [expr {1.*$a4/$Ref}]}
          set Io1 $a4
        }
        if {!$calc($name,Io2)} {
          set Io2 0
        } else {
          set a5 [expr {1.*([lindex $calc($name,Iсв2,2,$pnt) $i] - [lindex $calc($name,Bcur,2,$pnt) $i])}]
          if {$a5<0} {set a5 0}
          set Ref [lindex $calc($name,Ref,2,$pnt) $i]
          if {$Ref!=0} {set a5 [expr {1.*$a5/$Ref}]}
          set Io2 $a5
        }
        lappend calc($name,Io,$pnt) [expr {1.*[lindex $calc($name,coef) $i]*($Io1 + $Io2)/($calc($name,Io1) + $calc($name,Io2))}]
        incr i
      }
      set calc($name,Io,$pnt,cut) [lrange $calc($name,Io,$pnt) $min $max]
      if {$wms($name,type)=="swms"} {
        if {$lrep1!="no" && $lrep2!="no"} {
          set calc($name,Io,$pnt,cut)  [lreplace $calc($name,Io,$pnt,cut)  $lrep1 $lrep2]
        }
      }
    }
  } else {
    set calc($name,Io) {}
    set i 0
    catch {global x${name}Spec2 y${name}Spec2}
    foreach lamda $calc($name,lamda) {
      set Io 0
      foreach item $calc($name,Io,cntlist) {
        set a6 [expr {1.*([lindex $calc($name,Iразв,0,$item) $i] - [lindex $calc($name,Bcur,0,$item) $i])}]
        if {$a6<0} {set a6 0}
        set Ref [lindex $calc($name,Ref,0,$item) $i]
        if {$Ref!=0} {set a [expr {1.*$a6/$Ref}]}
        set Io [expr {$Io + $a6}]
      }
      lappend calc($name,Io) [expr {(1.+$wms($name,corIo)/100.)*$Io/[llength $calc($name,Io,cntlist)]}]
      incr i

      set x${name}Spec2(++end) $lamda
      set y${name}Spec2(++end) [lindex $calc($name,Io) end]
    }
    set calc($name,Io,cut) [lrange $calc($name,Io) $min $max]
    if {$wms($name,type)=="swms"} {
      if {$lrep1!="no" && $lrep2!="no"} {
        set calc($name,Io,cut)  [lreplace $calc($name,Io,cut)  $lrep1 $lrep2]
      }
    }
  }
  UnimodN_Disp $name $file
}

proc UnimodN_Disp {name file} {
global calc wms
global y${name}C y${name}Cm y${name}X y${name}r y${name}rm x${name} y${name}temp
global c33 c41 a33 a41

  set pi [expr {acos(-1)}]
  set date [clock format [clock seconds] -format "%y_%m_%d"]

  if {[lindex $calc($name,lamda,cut) 0]<[lindex $calc($name,lamda,cut) 1]} {
    set ln_UV [lindex $calc($name,lamda,cutnmb) 0]
    set ln_IR [lindex $calc($name,lamda,cutnmb) end]
  } else {
    set ln_UV [lindex $calc($name,lamda,cutnmb) end]
    set ln_IR [lindex $calc($name,lamda,cutnmb) 0]
  }

  if {[lindex $calc($name,s,cut) 0]<[lindex $calc($name,s,cut) 1]} {
    set calc($name,s,decr) ""
    foreach s_item $calc($name,s,cut) {
      set i 0
      set fl 1
      while {$fl} {
        if {$s_item>=[lindex $calc($name,s,decr) $i]} {
          set calc($name,s,decr) [linsert $calc($name,s,decr) $i $s_item]
          set fl 0
        }
        incr i
      }
    }
  }  else {
    set calc($name,s,decr) $calc($name,s,cut)
  }
  set s_UV [lindex $calc($name,s,decr)   0]
  set s_IR [lindex $calc($name,s,decr) end]

  set of3 [open $file/${name}_Gs.txt "w"]
  puts -nonewline $of3 "Дата: ${date}; "
  puts -nonewline $of3 "Имя_режима: $calc($name,dae); "
  puts -nonewline $of3 "Имя_замера: $calc($name,mn); "
  puts -nonewline $of3 "Имя_зонда: $name; "
  puts -nonewline $of3 "Тип Модуля: $wms($name,type) "
  puts $of3 ""

  puts -nonewline $of3 "hh:mm:ss"
  puts -nonewline $of3 "[format "%5s" N]"
  puts -nonewline $of3 "[format "%7s" X]"
  puts -nonewline $of3 "[format "%7s" ALFA]"

  foreach k $calc($name,lamda,cutnmb) {
    set lamda [lindex $calc($name,lamda,cut) $k]
    puts -nonewline $of3 "[format "%15s" Io/I($lamda)]"
    puts -nonewline $of3 "[format "%15s" G($lamda)]"
    puts -nonewline $of3 "[format "%15s" Gs($lamda)]"
    puts -nonewline $of3 "[format "%15s" Gps($lamda)]"
  }

  puts $of3 ""

  set of4 [open $file/${name}_IIo.txt "w"]

  puts -nonewline $of4 "Дата: ${date}; "
  puts -nonewline $of4 "Имя_режима: $calc($name,dae); "
  puts -nonewline $of4 "Имя_замера: $calc($name,mn); "
  puts -nonewline $of4 "Имя_зонда: $name; "
  puts -nonewline $of4 "Тип Модуля: $wms($name,type) "
  puts $of4 ""

  puts -nonewline $of4 "[format "%7s" X]"

  foreach k $calc($name,lamda,cutnmb) {
    set lamda [lindex $calc($name,lamda,cut) $k]
    puts -nonewline $of4 "[format "%15s" $lamda]"
  }

  puts $of4 ""

  set dl [format "%5.2E" 0.8e-6]
  set nd 11
#  set ld 4
  set ld 8
  set c33  0.106
  set c41  0.161
  set a33  0.130
  set a41  0.130

  set calc(hki33) {}
  set calc(hki41) {}

  set h [expr {1.*([lindex $calc(ro) end] - [lindex $calc(ro) 0])/([llength $calc(ro)] - 1)}]
# Vychislenie Integrala ot K/ro**2

  set cnt 0
  foreach ro $calc(ro) {
    if {!$cnt} {
      lappend calc(hki33) [expr {$c33/3.0*pow($ro,3)}]
      lappend calc(hki41) [expr {$c41/3.0*pow($ro,3)}]
    } else {
      lappend calc(hki33) [expr {1.*[lindex $calc(hki33) $cnt-1] + 0.5*$h*([lindex $calc(hk33) $cnt-1] + [lindex $calc(hk33) $cnt])}]
      lappend calc(hki41) [expr {1.*[lindex $calc(hki41) $cnt-1] + 0.5*$h*([lindex $calc(hk41) $cnt-1] + [lindex $calc(hk41) $cnt])}]
    }
    incr cnt
  }

  set of [open $file/${name}_calc.txt "w"]

  puts -nonewline $of "Дата: ${date}; "
  puts -nonewline $of "Имя_режима: $calc($name,dae); "
  puts -nonewline $of "Имя_замера: $calc($name,mn); "
  puts -nonewline $of "Имя_зонда: $name; "
  puts -nonewline $of "Тип Модуля: $wms($name,type) "
  puts $of ""

  puts -nonewline $of "hh:mm:ss"
  puts -nonewline $of "[format "%5s" N]"
  puts -nonewline $of "[format "%7s" X]"
  puts -nonewline $of "[format "%7s" ALFA]"
  if {$name!="A1" && $name!="A2"} {
    puts -nonewline $of "[format "%8s" RadP(W)]"
    puts -nonewline $of "[format "%8s" RadP(T)]"
  }
  puts -nonewline $of "[format "%7s" T,C]"
  puts -nonewline $of "[format "%14s" C(2)_[string range $calc($name,mn) end-1 end]]"
  puts -nonewline $of "[format "%14s" C(int_[llength $calc($name,lamda,cutnmb)])_[string range $calc($name,mn) end-1 end]]"
  puts -nonewline $of "[format "%14s" C(old_$calc(oldred))]"
  puts -nonewline $of "[format "%14s" C(old_$calc(oldblu))]"
  puts -nonewline $of "[format "%14s" C(2w_Aver)_[string range $calc($name,mn) end-1 end]]"
  puts $of ""

  set of5 [open $file/${name}.acn "w"]

  puts -nonewline $of5 "Дата: ${date}; "
  puts -nonewline $of5 "Имя_режима: $calc($name,dae); "
  puts -nonewline $of5 "Имя_замера: $calc($name,mn); "
  puts -nonewline $of5 "Имя_зонда: $name; "
  puts -nonewline $of5 "Тип Модуля: $wms($name,type) "
  puts $of5 ""

  puts -nonewline $of5 "hh:mm:ss"
  puts -nonewline $of5 "[format "%5s" N]"
  puts -nonewline $of5 "[format "%7s" X]"
  if {$name!="A1" && $name!="A2"} {
    puts -nonewline $of5 "[format "%8s" RadP(W)]"
    puts -nonewline $of5 "[format "%8s" RadP(T)]"
  }
  puts -nonewline $of5 "[format "%7s" T,C]"
  puts -nonewline $of5 "[format "%14s" Cint]"
  puts -nonewline $of5 "[format "%14s" C2w]"
  puts -nonewline $of5 "[format "%14s" r32_int]"
  puts -nonewline $of5 "[format "%14s" rzaut_2w]"
  puts $of5 ""

  set of2 [open $file/${name}_rsr.txt "w"]

  puts -nonewline $of2 "Дата: ${date}; "
  puts -nonewline $of2 "Имя_режима: $calc($name,dae); "
  puts -nonewline $of2 "Имя_замера: $calc($name,mn); "
  puts -nonewline $of2 "Имя_зонда: $name; "
  puts -nonewline $of2 "Тип Модуля: $wms($name,type) "
  puts $of2 ""

  puts -nonewline $of2 "hh:mm:ss"
  puts -nonewline $of2 "[format "%5s" N]"
  puts -nonewline $of2 "[format "%7s" X]"
  puts -nonewline $of2 "[format "%7s" ALFA]"
  if {$name!="A1" && $name!="A2"} {
    puts -nonewline $of2 "[format "%8s" RadP(W)]"
    puts -nonewline $of2 "[format "%8s" RadP(T)]"
  }
  puts -nonewline $of2 "[format "%14s" rsr_[string range $calc($name,mn) end-1 end]]"
  puts -nonewline $of2 "[format "%14s" r43_int_[string range $calc($name,mn) end-1 end]]"
  puts -nonewline $of2 "[format "%14s" r32_int_[string range $calc($name,mn) end-1 end]]"
  puts -nonewline $of2 "[format "%14s" ro_[string range $calc($name,mn) end-1 end]]"
  puts -nonewline $of2 "[format "%14s" F_2w_[string range $calc($name,mn) end-1 end]]"
  puts -nonewline $of2 "[format "%14s" rzaut_2w_[string range $calc($name,mn) end-1 end]]"
  puts -nonewline $of2 "[format "%15s" rozaut($calc(oldred))]"
  puts -nonewline $of2 "[format "%15s" rozaut($calc(oldblu))]"
  puts -nonewline $of2 "[format "%14s" K($calc(oldred))]"
  puts -nonewline $of2 "[format "%14s" K($calc(oldblu))]"
  puts $of2 ""

  for {set pnt 0} {$pnt<=$calc($name,points)} {incr pnt} {

    if {$wms(top)} {
      .fr.bt configure -text "[format "%3.0f" $calc($name,X,$pnt)] $pnt [expr {$calc($name,points)-$pnt}]"
    } else {

      .fr1.com.startlf.lb configure -text "$pnt [expr {$calc($name,points)-$pnt}]"
    }
    set wms(mpoint) "$pnt [expr {$calc($name,points)-$pnt}]"
    update

    if {$calc($name,T,$pnt)>0} {
      set t $calc($name,T,$pnt)
    } else {
      set t 50
    }

    if {$name!="A1" && $name!="A2"} {
      if {![info exists calc($name,RWI)]} {

        set calc($name,RWI) $wms($name,RWI)
        set calc($name,RTI) $wms($name,RTI)
        set calc($name,RH) $wms($name,RH)
        set calc($name,RC) $wms($name,RC)
      }
      set calc($name,RadPw,$pnt) [expr {($calc($name,RWI) - $calc($name,X,$pnt) - $calc($name,RH))/($calc($name,RC) - $calc($name,RH))}]
      set calc($name,RadPt,$pnt) [expr {($calc($name,RTI) - $calc($name,X,$pnt) - $calc($name,RH))/($calc($name,RC) - $calc($name,RH))}]
    }

    set calc($name,am2,$pnt) 0
    set calc($name,amn,$pnt) 0
    set calc($name,amold_$calc($name,2w,red),$pnt) 0
    set calc($name,amold_$calc($name,2w,blu),$pnt) 0
    set calc($name,amold_aver,$pnt) 0
    set calc($name,rsr,$pnt) 0
    set calc($name,rz43,$pnt) 0
    set calc($name,rz32,$pnt) 0
    set ro 0
    set f 0
    set rzaut 0
    set rozaut($calc($name,2w,red)) 0
    set rozaut($calc($name,2w,blu)) 0
    set K($calc($name,2w,red)) 1
    set K($calc($name,2w,blu)) 1

    if {$calc($name,wet,$pnt)} {
      set calc($name,maxIIo,$pnt) 0
      set calc($name,delta,$pnt)  0

      set N [expr {$pnt+1}]

###
##### Rastchet G=log(Io/I) i Gs=G/s**2
###
      set flag($pnt) 0


      if {$calc(old)} {
        set b [list $calc($name,red,index) $calc($name,blu,index)]
      } else {
        set b ""
      }

      foreach k [concat $calc($name,lamda,cutnmb) $b] {
        set calc($name,IIo,$k)   0
        set calc($name,G,$k)   0
        set calc($name,Gs,$k)  0
        set calc($name,Gps,$k) 0
      }

      if {$wms($name,type)=="swms" || $wms($name,type)=="test"} {
        set aver [expr {($calc(aver)-1)/2}]
      } else {
        set aver 0
      }

      set cnt 0
      catch {global x${name}Spec22 y${name}Spec22}
      catch {global x${name}I_Io y${name}I_Io}

      foreach k [concat $calc($name,lamda,cutnmb) $b] {

        set Io_aver 0
        set I_aver 0
        set Ref_aver 0

        for {set i [expr {$k-$aver}]} {$i<=[expr {$k+$aver}]} {incr i} {
          if {(!$calc($name,Io1) && !$calc($name,Io2)) || $calc($name,new_meth)} {
            set Io  [lindex $calc($name,Io,cut) $i]
          } else {
            set Io  [lindex $calc($name,Io,$pnt,cut) $i]
          }

          set I [expr {[lindex $calc($name,Iразв,0,$pnt,cut) $i] - [lindex $calc($name,Bcur,0,$pnt,cut) $i]}]
          set Ref [lindex $calc($name,Ref,0,$pnt,cut) $i]

          set Io_aver  [expr {$Io_aver+$Io}]
          set I_aver   [expr {$I_aver+$I}]
          set Ref_aver [expr {$Ref_aver+$Ref}]
        }

        set Io  [expr {1.*$Io_aver/$calc(aver)}]
        set I   [expr {1.*$I_aver/$calc(aver)}]
        set Ref [expr {1.*$Ref_aver/$calc(aver)}]
        if {$Ref!=0} {set I [expr {1.*$I/$Ref}]}

        set lamda [lindex $calc($name,lamda,cut) $k]
        set s     [lindex $calc($name,s,cut) $k]


        if {$cnt<[llength $calc($name,lamda,cutnmb)]} {

          set x${name}Spec22(++end) $lamda
          set y${name}Spec22(++end) $I

          set x${name}I_Io(++end) $lamda
          if {$Io>0 && $I>0} {
            set calc($name,IIo,$k) [expr {1.*$I/$Io}]
            set y${name}I_Io(++end) [expr {1.*$I/$Io}]
          } else {
            set y${name}I_Io(++end) 1
          }
        }

        if {$Io>0 && $I>0 && $flag($pnt)<2} {
          if {$Io>$I} {
            set calc($name,G,$k)  [expr {log($Io*1./$I)}]
            set calc($name,Gs,$k) [expr {1.*$calc($name,G,$k)/pow($s,2)}]
          } else {

            set tol   [expr {($I/$Io-1)*100.}]
            set delta [expr {$I-$Io}]

            if {$tol>$calc($name,maxIIo,$pnt)}  {set calc($name,maxIIo,$pnt) $tol}
            if {$delta>$calc($name,delta,$pnt)} {set calc($name,delta,$pnt) $delta}

            if {$tol>$wms(tolerance)} {
              set flag($pnt) 3
            } else {
              set l_bord 530000
              set calc($name,l_bord,point) [lindex $calc($name,lamda,cut) $k]
              if {$calc($name,l_bord,point)>$l_bord} {
                set flag($pnt) 1
              } else {
                set flag($pnt) 5
              }
            }
          }
        } else {
          if {$flag($pnt)<2} {set flag($pnt) 4}
        }
        incr cnt
      }
## Корректировка I и Rastchet G=log(Io/I) i Gs=G/s**2
      if {$flag($pnt)<4} {
        foreach k [concat $calc($name,lamda,cutnmb) $b] {

          set Io_aver 0
          set I_aver 0
          set Ref_aver 0

          for {set i [expr {$k-$aver}]} {$i<=[expr {$k+$aver}]} {incr i} {
            if {(!$calc($name,Io1) && !$calc($name,Io2)) || $calc($name,new_meth)} {
              set Io  [lindex $calc($name,Io,cut) $i]
            } else {
              set Io  [lindex $calc($name,Io,$pnt,cut) $i]
            }

            set I [expr {[lindex $calc($name,Iразв,0,$pnt,cut) $i] - [lindex $calc($name,Bcur,0,$pnt,cut) $i]}]
            set Ref [lindex $calc($name,Ref,0,$pnt,cut) $i]

            set Io_aver  [expr {$Io_aver+$Io}]
            set I_aver   [expr {$I_aver+$I}]
            set Ref_aver [expr {$Ref_aver+$Ref}]
          }

          set Io  [expr {1.*$Io_aver/$calc(aver)}]
          set I   [expr {1.*$I_aver/$calc(aver)}]
          set Ref [expr {1.*$Ref_aver/$calc(aver)}]
          if {$Ref!=0} {set I [expr {1.*$I/$Ref}]}

          set s_max [lindex $calc($name,s,cut) 0]
          set s_min [lindex $calc($name,s,cut) end]
          if {$s_min>$s_max} {set s_max $s_min}
          set Io_cor [expr {1.*($Io + $calc($name,delta,$pnt))*exp(pow($s_max,2)*$dl)}]

          set lamda [lindex $calc($name,lamda,cut) $k]
          set s     [lindex $calc($name,s,cut) $k]

          set calc($name,IIo,$k) [expr {1.*$I/$Io_cor}]
          if {[expr {$Io_cor*$I} > 0]} {
            set calc($name,G,$k)  [expr {log(1.*$Io_cor/$I)}]
          } else {
            set calc($name,G,$k) 0
          }
          set calc($name,Gs,$k) [expr {1.*$calc($name,G,$k)/pow($s,2)}]
        }
      }

### Vychislenie rsr

      set q($pnt) 0
      if {$calc($name,Gs,$ln_IR)!=0} {
        set q($pnt) [expr {1.*$calc($name,Gs,$ln_UV)/$calc($name,Gs,$ln_IR)}]
        set calc($name,rsr,$pnt) [rr2_Disp $q($pnt) $s_IR $s_UV $t]
      }
      set rzaut 0

### Raschet po 2m stary`m dlinnam voln

      set red $calc($name,red,index)
      set blu $calc($name,blu,index)

      if {$calc(old) && $red!=-1 && $blu!=-1 && $calc($name,G,$red)>0 && $calc($name,G,$blu)>0} {
        set f [expr {1.*$calc($name,G,$blu)/$calc($name,G,$red)}]
        set rzaut [FindR  $f]
        set rozaut($calc($name,2w,red)) [expr {$rzaut*2.*$pi*pow(10,6)/[lindex $calc($name,lamda,cut) $red]}]
        set rozaut($calc($name,2w,blu)) [expr {$rzaut*2.*$pi*pow(10,6)/[lindex $calc($name,lamda,cut) $blu]}]
        set K($calc($name,2w,red)) [FindKro $rozaut($calc($name,2w,red))]
        set K($calc($name,2w,blu)) [FindKro $rozaut($calc($name,2w,blu))]
        set calc($name,amold_$calc($name,2w,red),$pnt) [expr {4.*$rzaut*$calc($name,G,$red)/($K($calc($name,2w,red))*3.*$calc($name,L)*1000.)}]
        set calc($name,amold_$calc($name,2w,blu),$pnt) [expr {4.*$rzaut*$calc($name,G,$blu)/($K($calc($name,2w,blu))*3.*$calc($name,L)*1000.)}]
        set calc($name,amold_aver,$pnt) [expr {1.*($calc($name,amold_$calc($name,2w,red),$pnt)+$calc($name,amold_$calc($name,2w,blu),$pnt))/2.}]
      }

### отсеивание нулевых значений и ошибок эксперимента
      foreach k $calc($name,lamda,cutnmb) {
        if {$flag($pnt)<2} {
          if {$calc($name,Gs,$k)<$dl} {
            set flag($pnt) 2
            set calc($name,Gs,dl,$pnt) [format "%5.2E" $calc($name,Gs,$k)]
            set calc($name,Gs,l,$pnt)  [lindex $calc($name,lamda,cut) $k]
          }
        }
      }

      if {$flag($pnt)<3} {
### Vychisleniу Integrala ot G**2
        foreach k $calc($name,lamda,cutnmb) {
          set s [lindex $calc($name,s,cut) $k]
          set ro [expr {1.*$s*$calc($name,rsr,$pnt)}]
          set j [hk2_Disp $ro $s $t]

          set calc($name,$pnt,gg2,$k) [expr {pow($calc($name,Gs,$k),2)}]
          set calc($name,$pnt,gk2,$k) [expr {$calc($name,Gs,$k)*$j}]
          set calc($name,$pnt,kk2,$k) [expr {pow($j,2)}]
        }

        set g2 [hintr_Disp $name $pnt gg2]
        set gk [hintr_Disp $name $pnt gk2]
        set kk [hintr_Disp $name $pnt kk2]

        set g0  [expr {1.*$gk/$kk}]
        set am2 [expr {$g0/$calc($name,rsr,$pnt)/$calc($name,L)/1000.}]


### nahodim 1-oe priblizhenie dlia 3-ego momenta po 2-m krai`nim tochkam
### G(s) ishchem v vide g0*K(rsr*s)

        set calc($name,am2,$pnt) [expr {4.*$am2/3.}]

### ishchem 3-ii` moment po k dlinam voln
### nachal`ny`e znacheniia dlia podprogrammy` mnk

      set calc($name,rn1,$pnt) [expr {0.3*$calc($name,rsr,$pnt)}]
      set calc($name,rn2,$pnt) [expr {1.2*$calc($name,rsr,$pnt)}]
      set calc($name,rv1,$pnt) [expr {0.7*$calc($name,rsr,$pnt)}]
      set calc($name,rv2,$pnt) [expr {2.0*$calc($name,rsr,$pnt)}]

        for {set j 1} {$j<=$ld} {incr j} {
          set calc($name,hn,$pnt)  [expr {1.*($calc($name,rn2,$pnt) - $calc($name,rn1,$pnt))/($nd-1)}]
          set calc($name,hv,$pnt)  [expr {1.*($calc($name,rv2,$pnt) - $calc($name,rv1,$pnt))/($nd-1)}]

          MNK_Disp $nd $name $pnt $t $g2

          if {$calc($name,rn,$pnt)<=$calc($name,rn1,$pnt)} {

            set calc($name,rn1,$pnt) $calc($name,rn,$pnt)
          } else {

            set calc($name,rn1,$pnt) [expr {$calc($name,rn,$pnt) - $calc($name,hn,$pnt)}]
          }

          if {$calc($name,rn,$pnt)>=$calc($name,rn2,$pnt)} {

            set calc($name,rn2,$pnt) $calc($name,rn,$pnt)
          } else {

            set calc($name,rn2,$pnt) [expr {$calc($name,rn,$pnt) + $calc($name,hn,$pnt)}]
          }

          if {$calc($name,rv,$pnt)>=$calc($name,rv2,$pnt)} {

            set calc($name,rv2,$pnt) $calc($name,rv,$pnt)
          } else {

            set calc($name,rv2,$pnt) [expr {$calc($name,rv,$pnt) + $calc($name,hv,$pnt)}]
          }

          if {$calc($name,rv,$pnt)<=$calc($name,rv1,$pnt)} {

            set calc($name,rv1,$pnt) $calc($name,rv,$pnt)
          } else {

            set calc($name,rv1,$pnt) [expr {$calc($name,rv,$pnt) - $calc($name,hv,$pnt)}]
          }

          set calc($name,hn,$pnt) [expr {2.*$calc($name,hn,$pnt)/($nd-1)}]
          set calc($name,hv,$pnt) [expr {2.*$calc($name,hv,$pnt)/($nd-1)}]
        }
        set calc($name,amn,$pnt)   [expr {4.*$calc($name,g0,$pnt)*log($calc($name,rv,$pnt)/$calc($name,rn,$pnt))/(3.*$calc($name,L)*1000.)}]
        set calc($name,rz43,$pnt)  [expr {1.*($calc($name,rv,$pnt) - $calc($name,rn,$pnt))/log($calc($name,rv,$pnt)/$calc($name,rn,$pnt))}]
        set calc($name,rz32,$pnt)  [expr {1.*$calc($name,rv,$pnt)*$calc($name,rn,$pnt)/($calc($name,rv,$pnt) - $calc($name,rn,$pnt))*log($calc($name,rv,$pnt)/$calc($name,rn,$pnt))}]
#Vy`chislenie priblizheniia G(s)   Gp(s)
#Gp(s)=g0/s*(hk2in(s*rv)-hk2in(s*rn))

        foreach k $calc($name,lamda,cutnmb) {

          set s [lindex $calc($name,s,cut) $k]
          set calc($name,Gps,$k)  [expr {1.*$calc($name,g0,$pnt)/$s*([hk2in_Disp [expr {1.*$s*$calc($name,rv,$pnt)}] $s $t] - [hk2in_Disp [expr {1.*$s*$calc($name,rn,$pnt)}] $s $t])}]
        }
      }

      if {![info exists calc($name,amold_aver,$pnt)] || $calc($name,amold_aver,$pnt)==""} {set calc($name,amold_aver,$pnt) 0}
      set x${name}(++end) $calc($name,X,$pnt)
#      set y${name}temp(++end) $t
      set y${name}C(++end) $calc($name,amold_aver,$pnt)
      set y${name}Cm(++end) $calc($name,amn,$pnt)
      set y${name}X(++end) [expr {1  - 1.*$calc($name,amold_aver,$pnt)/($calc($name,amold_aver,$pnt) + $calc($name,Dens,$pnt)/1000)}]
      set y${name}r(++end) $rzaut
      set y${name}rm(++end) $calc($name,rz32,$pnt)

      puts -nonewline $of "$calc($name,time,$pnt)"
      puts -nonewline $of " [format "%04d"   $N]"
      puts -nonewline $of "[format "%7.2f"  $calc($name,X,$pnt)]"
      puts -nonewline $of "[format "%7.2f"  $calc($name,Y,$pnt)]"
      if {$name!="A1" && $name!="A2"} {
        puts -nonewline $of "[format "%8.4f"  $calc($name,RadPw,$pnt)]"
        puts -nonewline $of "[format "%8.4f"  $calc($name,RadPt,$pnt)]"
      }
      puts -nonewline $of "[format "%7.2f"  $calc($name,T,$pnt)]"
      puts -nonewline $of "[format "%14.6E" $calc($name,am2,$pnt)]"
      puts -nonewline $of "[format "%14.6E" $calc($name,amn,$pnt)]"
      puts -nonewline $of "[format "%14.6E" $calc($name,amold_$calc($name,2w,red),$pnt)]"
      puts -nonewline $of "[format "%14.6E" $calc($name,amold_$calc($name,2w,blu),$pnt)]"
      puts -nonewline $of "[format "%14.6E" $calc($name,amold_aver,$pnt)]"

      puts -nonewline $of5 "$calc($name,time,$pnt)"
      puts -nonewline $of5 " [format "%04d"   $N]"
      puts -nonewline $of5 "[format "%7.2f"  $calc($name,X,$pnt)]"
      if {$name!="A1" && $name!="A2"} {
        puts -nonewline $of5 "[format "%8.4f"  $calc($name,RadPw,$pnt)]"
        puts -nonewline $of5 "[format "%8.4f"  $calc($name,RadPt,$pnt)]"
      }
      puts -nonewline $of5 "[format "%7.2f"  $calc($name,T,$pnt)]"
      puts -nonewline $of5 "[format "%14.6E" $calc($name,amn,$pnt)]"
      puts -nonewline $of5 "[format "%14.6E" $calc($name,amold_aver,$pnt)]"
      puts -nonewline $of5 "[format "%14.6E" $calc($name,rz32,$pnt)]"
      puts -nonewline $of5 "[format "%14.6E" $rzaut]"

      puts -nonewline $of2 "$calc($name,time,$pnt)"
      puts -nonewline $of2 " [format "%04d"  $N]"
      puts -nonewline $of2 "[format "%7.2f"  $calc($name,X,$pnt)]"
      puts -nonewline $of2 "[format "%7.2f"  $calc($name,Y,$pnt)]"
      if {$name!="A1" && $name!="A2"} {
        puts -nonewline $of2 "[format "%8.4f"  $calc($name,RadPw,$pnt)]"
        puts -nonewline $of2 "[format "%8.4f"  $calc($name,RadPt,$pnt)]"
      }
      puts -nonewline $of2 "[format "%14.6E" $calc($name,rsr,$pnt)]"
      puts -nonewline $of2 "[format "%14.6E" $calc($name,rz43,$pnt)]"
      puts -nonewline $of2 "[format "%14.6E" $calc($name,rz32,$pnt)]"
      puts -nonewline $of2 "[format "%14.6E" $ro]"
      puts -nonewline $of2 "[format "%14.6E" $f]"
      puts -nonewline $of2 "[format "%14.6E" $rzaut]"
      puts -nonewline $of2 "[format "%15.6E" $rozaut($calc($name,2w,red))]"
      puts -nonewline $of2 "[format "%15.6E" $rozaut($calc($name,2w,blu))]"
      puts -nonewline $of2 "[format "%14.4E" $K($calc($name,2w,red))]"
      puts -nonewline $of2 "[format "%14.4E" $K($calc($name,2w,blu))]"

      puts -nonewline $of3 "$calc($name,time,$pnt)"
      puts -nonewline $of3 " [format "%04d" $N]"
      puts -nonewline $of3 "[format "%7.2f" $calc($name,X,$pnt)]"
      puts -nonewline $of3 "[format "%7.2f" $calc($name,Y,$pnt)]"
      foreach k $calc($name,lamda,cutnmb) {
        puts -nonewline $of3 "[format "%15.6E" $calc($name,IIo,$k)]"
        puts -nonewline $of3 "[format "%15.6E" $calc($name,G,$k)]"
        puts -nonewline $of3 "[format "%15.6E" $calc($name,Gs,$k)]"
        puts -nonewline $of3 "[format "%15.6E" $calc($name,Gps,$k)]"
      }

      puts -nonewline $of4 "[format "%7.2f" $calc($name,X,$pnt)]"
      foreach k $calc($name,lamda,cutnmb) {
        puts -nonewline $of4 "[format "%15.6E" $calc($name,IIo,$k)]"
      }

      switch $flag($pnt) {
        "1" {
          puts -nonewline $of  " Погрешность измерений Io/I<1 maxIIo=[format "%4.3f" $calc($name,maxIIo,$pnt)]% < $wms(tolerance)% Корректировка Io на (Io+$calc($name,delta,$pnt))*exp(pow($s_max,2)*$dl)"
          puts -nonewline $of5 " Погрешность измерений Io/I<1 maxIIo=[format "%4.3f" $calc($name,maxIIo,$pnt)]% < $wms(tolerance)% Корректировка Io на (Io+$calc($name,delta,$pnt))*exp(pow($s_max,2)*$dl)"
          puts -nonewline $of2 " Погрешность измерений Io/I<1 maxIIo=[format "%4.3f" $calc($name,maxIIo,$pnt)]% < $wms(tolerance)% Корректировка Io на (Io+$calc($name,delta,$pnt))*exp(pow($s_max,2)*$dl)"
        }
        "2" {
          puts -nonewline $of  " Погрешность измерений Gs($calc($name,Gs,l,$pnt))=$calc($name,Gs,dl,$pnt) < $dl"
          puts -nonewline $of5 " Погрешность измерений Gs($calc($name,Gs,l,$pnt))=$calc($name,Gs,dl,$pnt) < $dl"
          puts -nonewline $of2 " Погрешность измерений Gs($calc($name,Gs,l,$pnt))=$calc($name,Gs,dl,$pnt) < $dl"
        }
        "3" {
          puts -nonewline $of  " Погрешность измерений Io/I<1; maxIIo=[format "%4.3f" $calc($name,maxIIo,$pnt)]% > $wms(tolerance)%"
          puts -nonewline $of5 " Погрешность измерений Io/I<1; maxIIo=[format "%4.3f" $calc($name,maxIIo,$pnt)]% > $wms(tolerance)%"
          puts -nonewline $of2 " Погрешность измерений Io/I<1; maxIIo=[format "%4.3f" $calc($name,maxIIo,$pnt)]% > $wms(tolerance)%"
        }
        "4" {
          puts -nonewline $of  " Некорректный замер Io или I <0"
          puts -nonewline $of5 " Некорректный замер Io или I <0"
          puts -nonewline $of2 " Некорректный замер Io или I <0"
        }
        "5" {
          puts -nonewline $of  " Погрешность измерений Io/I<1 на длине волны $calc($name,l_bord,point) нм < $l_bord нм"
          puts -nonewline $of5 " Погрешность измерений Io/I<1 на длине волны $calc($name,l_bord,point) нм < $l_bord нм"
          puts -nonewline $of2 " Погрешность измерений Io/I<1 на длине волны $calc($name,l_bord,point) нм < $l_bord нм"
        }
      }
      puts $of ""
      puts $of2 ""
      puts $of3 ""
      puts $of4 ""
    } else {

      set N [expr {$pnt+1}]

      puts -nonewline $of5 "$calc($name,time,$pnt)"
      puts -nonewline $of5 " [format "%04d"   $N]"
      puts -nonewline $of5 "[format "%7.2f"  $calc($name,X,$pnt)]"
      if {$name!="A1" && $name!="A2"} {
        puts -nonewline $of5 "[format "%8.4f"  $calc($name,RadPw,$pnt)]"
        puts -nonewline $of5 "[format "%8.4f"  $calc($name,RadPt,$pnt)]"
      }
      puts -nonewline $of5 "[format "%7.2f"  $calc($name,T,$pnt)]"
      puts -nonewline $of5 "[format "%14.6E" $calc($name,amn,$pnt)]"
      puts -nonewline $of5 "[format "%14.6E" $calc($name,amold_aver,$pnt)]"
      puts -nonewline $of5 "[format "%14.6E" $calc($name,rz32,$pnt)]"
      puts -nonewline $of5 "[format "%14.6E" $rzaut]"

      set x${name}(++end) $calc($name,X,$pnt)
#      set y${name}temp(++end) $t
      set y${name}C(++end)  0
      set y${name}Cm(++end)  0
      set y${name}X(++end)  0
      set y${name}r(++end)  0
      set y${name}rm(++end)  0
    }
    puts $of5 ""
update
  }
  puts $of ""
  puts $of "corIo= $wms($name,corIo) %"
  close $of5
  close $of4
  close $of3
  close $of2
  close $of

#  if {$wms(top)} {.fr.bt configure -state active -text "Push"}
}

proc MNK_Disp {nd name i t g2} {
global calc

  set dl 10.0
  set calc($name,g0,$i) 1.0
#  set sg 0.0

#  foreach k $calc($name,lamda,cutnmb) {

#    set sg [expr {$sg+pow($calc($name,Gs,$k),2)}]
#  }

  for {set j 1} {$j<=$nd} {incr j} {

    set r1 [expr {$calc($name,rn1,$i) + ($j-1)*($calc($name,rn2,$i) - $calc($name,rn1,$i))/($nd-1)}]
    for {set h 1} {$h<=$nd} {incr h} {

      set r2 [expr {$calc($name,rv1,$i) + ($h-1)*($calc($name,rv2,$i) - $calc($name,rv1,$i))/($nd-1)}]
      if {$r1<[expr {$r2*0.999}]} {
        foreach k $calc($name,lamda,cutnmb) {

          set s [lindex $calc($name,s,cut) $k]
          set ro1 [expr {$s*$r1}]
          set ro2 [expr {$s*$r2}]
          set calc($name,$i,kk,$k) [expr {pow(1./$s*([hk2in_Disp $ro2 $s $t] - [hk2in_Disp $ro1 $s $t]),2)}]
          set calc($name,$i,gk,$k) [expr {1.0/$s*([hk2in_Disp  $ro2 $s $t] - [hk2in_Disp $ro1 $s $t])*$calc($name,Gs,$k)}]
        }
      }

      set gk2 [hintr_Disp $name $i gk]
      set k2  [hintr_Disp $name $i kk]
      set gt [expr {$gk2/$k2}]
      set dlt [expr {$g2 - pow($gk2,2)/$k2}]

      if {$dlt<$dl} {
        set dl $dlt
        set calc($name,g0,$i) $gt
        set calc($name,rn,$i) $r1
        set calc($name,rv,$i) $r2
      }
    }
  }
}

# Metod deleniia popolam
proc rr2_Disp {dg s1 s2 t} {

  set r1 0.02
  set r2 1.0
  set ro11 [expr {1.*$r1*$s1}]
  set ro12 [expr {1.*$r1*$s2}]
  set ro21 [expr {1.*$r2*$s1}]
  set ro22 [expr {1.*$r2*$s2}]

  set dk1 [expr {[hk2_Disp $ro12 $s2 $t]/[hk2_Disp $ro11 $s1 $t]-$dg}]
  set dk2 [expr {[hk2_Disp $ro22 $s2 $t]/[hk2_Disp $ro21 $s1 $t]-$dg}]

  for {set i 0} {$i<10} {incr i} {

    set rr [expr {($r1+$r2)/2}]
    set dk [expr {[hk2_Disp [expr {$rr*$s2}] $s2 $t]/[hk2_Disp [expr {$rr*$s1}] $s1 $t]-$dg}]
    if {$dk>0} {
      set r1 $rr
      set dk1 $dk
    } else {
      set r2 $rr
      set dk2 $dk
    }
  }
  return $rr
}

# Integrirovanie po metodu tarpetcii`
proc hintr_Disp {name pnt y} {
global calc

   set yt 0.0
   set cnt 0
   foreach k $calc($name,lamda,cutnmb) {
     if {!$cnt} {

       set  s_old [lindex $calc($name,s,cut)   $k]
       set ys_old $calc($name,$pnt,$y,$k)
     } else {
       set s  [lindex $calc($name,s,cut)   $k]
       set ys $calc($name,$pnt,$y,$k)
       set yt [expr {$yt + 0.5*($s - $s_old)*($ys + $ys_old)}]
       set s_old  $s
       set ys_old $ys
     }
     incr cnt
   }
   return [expr {abs($yt)}]
}

# Vy`chislenie iadra K(ro)/ro**2

proc hk2_Disp {ro s t} {
global calc
global c33 c41 a33 a41

  set ro1 [lindex $calc(ro) 0]
  set ron [lindex $calc(ro) end]
  set nro [llength $calc(ro)]
  set hro [expr {($ron - $ro1)/($nro - 1)}]
  if {$ro<=$ro1} {
    set ht33 [expr {$c33*pow($ro,2)}]
    set ht41 [expr {$c41*pow($ro,2)}]
  } elseif {$ro>=$ron} {
    set ht33 [expr {2.0/pow(($ro - $a33),2)}]
    set ht41 [expr {2.0/pow(($ro - $a41),2)}]
  } else {
    set i [expr {round(1 + ($nro - 1)*(($ro - $ro1)/($ron - $ro1)))}]
    while {$i>=[llength $calc(hk33)]} {
       incr i -1
    }
    set ht33 [expr {[lindex $calc(hk33) $i-1]+([lindex $calc(hk33) $i] - [lindex $calc(hk33) $i-1])/$hro*($ro - $ro1 - ($i-1)*$hro)}]
    set ht41 [expr {[lindex $calc(hk41) $i-1]+([lindex $calc(hk41) $i] - [lindex $calc(hk41) $i-1])/$hro*($ro - $ro1 - ($i-1)*$hro)}]
  }
  set hk2 [expr {$ht33+($ht41 - $ht33)*([hn_Disp $t $s]-1.33)/0.08}]
  return $hk2
}

# Vy`chislenie integrala iadra K(ro)/ro**2
proc hk2in_Disp {ro s t} {
global calc
global c33 c41 a33 a41

  set ro1 [lindex $calc(ro) 0]
  set ron [lindex $calc(ro) end]
  set nro [llength $calc(ro)]
  set hro [expr {($ron - $ro1)/($nro - 1)}]
  if {$ro<=$ro1} {
    set hti33 [expr {$c33/3.0*pow($ro,3)}]
    set hti41 [expr {$c41/3.0*pow($ro,3)}]
  } elseif {$ro>=$ron} {
    set hti33 [expr {[lindex $calc(hki33) $nro-1] + 2.0/($ron - $a33) - 2.0/($ro - $a33)}]
    set hti41 [expr {[lindex $calc(hki41) $nro-1] + 2.0/($ron - $a41) - 2.0/($ro - $a41)}]
  } else {
    set i [expr {round(floor(1.0 + ($nro - 1)*(($ro - $ro1)/($ron - $ro1))))}]
    set hti33 [expr {[lindex $calc(hki33) $i-1]+([lindex $calc(hki33) $i] - [lindex $calc(hki33) $i-1])/$hro*($ro - $ro1 - ($i-1)*$hro)}]
    set hti41 [expr {[lindex $calc(hki41) $i-1]+([lindex $calc(hki41) $i] - [lindex $calc(hki41) $i-1])/$hro*($ro - $ro1 - ($i-1)*$hro)}]
  }
  set hk2in [expr {$hti33+($hti41 - $hti33)*([hn_Disp $t $s]-1.33)/0.08}]
  return $hk2in
}

# Vy`chislenie koe`ffitcienta prelomleniia
proc hn_Disp {t s} {

  set d  1.0
  set pi [expr {acos(-1)}]
  set dl [expr {2.*$pi/$s}]
  set d0 [expr {$dl/0.589}]
  set t0 [expr {1.+$t/273.15}]
  set duv 0.229202
  set dir 5.432937
  set a0  0.244258
  set a1  0.974634e-2
  set a2 -0.373235e-2
  set a3  0.268678e-3
  set a4  0.158921e-2
  set a5  0.245934e-2
  set a6  0.900705
  set a7 -0.166626e-1
  set a [expr {$d*($a0+$a1*$d+$a2*$t0+$a3*pow($d0,2)*$t0+$a4/pow($d0,2)+$a5/(pow($d0,2)\
         - pow($duv,2))+$a6/(pow($d0,2) - pow($dir,2))+$a7*pow($d,2))}]
  set hn [expr {pow((2.0*$a+1.0)/(1.0-$a),0.5) }]
  return $hn
}

ReadK2

proc Kro {ro nu} {

  switch $nu {
    1.33 {
#ЕСЛИ(C2<0.7;0.105277467*C2^3.97263098;ЕСЛИ(C2<1.5;0.2813*C2^2 - 0.2428*C2 + 0.0574;ЕСЛИ(C2>3.4;0.005034448*C2^4 - 0.1163905*C2^3 + 0.7727616*C2^2 - 0.9369164*C2^1 + 0.3426401;0.001484095*C2^4 - 0.08506329*C2^3 + 0.6852815*C2^2 - 0.8652747*C2^1 + 0.3595925)))
      if {$ro<=0.7} {
        set Kro [expr {0.105277467*pow($ro,3.97263098)}]
      } elseif {$ro<=1.5} {
        set Kro [expr {0.2813*pow($ro,2) - 0.2428*$ro + 0.0574}]
      } elseif {$ro<=3.4} {
        set Kro [expr {0.001484095*pow($ro,4) - 0.08506329*pow($ro,3) + 0.6852815*pow($ro,2) - 0.8652747*$ro + 0.3595925}]
      } elseif {$ro<=10} {
        set Kro [expr {0.005034448*pow($ro,4) - 0.1163905*pow($ro,3) + 0.7727616*pow($ro,2) - 0.9369164*$ro + 0.3426401}]
      } else {
        set Kro 2.0
      }
    }
    1.34 {
#ЕСЛИ(C2<0.3;0.106669*C2^3 - 0.0361137*C2^2 + 0.00534316*C2 - 0.000290763;ЕСЛИ(C2<1.05;-0.103742*C2^5 + 0.287909*C2^4 - 0.118705*C2^3 + 0.0405757*C2^2 - 0.0066431*C2 + 0.000411185;ЕСЛИ(C2<4;0.00793311*C2^4 - 0.153129*C2^3 + 0.934834*C2^2 - 1.19464*C2 + 0.50896;ЕСЛИ(C2<8.4;-0.000552182*C2^5 + 0.0223311*C2^4 - 0.320955*C2^3 + 1.89921*C2^2 - 3.82682*C2 + 3.22271;ЕСЛИ(C2<18.5;-0.00106188*C2^4 + 0.0397881*C2^3 - 0.412655*C2^2 + 0.210616*C2 + 12;2)))))
      if {$ro<=0.3} {
        set Kro [expr {0.106669*pow($ro,3) - 0.0361137*pow($ro,2) + 0.00534316*$ro - 0.000290763}]
      } elseif {$ro<=1.05} {
        set Kro [expr {-0.103742*pow($ro,5) + 0.287909*pow($ro,4) - 0.118705*pow($ro,3) + 0.0405757*pow($ro,2) - 0.0066431*$ro + 0.000411185}]
      } elseif {$ro<=4} {
        set Kro [expr {0.00793311*pow($ro,4) - 0.153129*pow($ro,3) + 0.934834*pow($ro,2) - 1.19464*$ro + 0.50896}]
      } elseif {$ro<=8.4} {
        set Kro [expr {-0.000552182*pow($ro,5) + 0.0223311*pow($ro,4) - 0.320955*pow($ro,3) + 1.89921*pow($ro,2) - 3.82682*$ro + 3.22271}]
      } elseif {$ro<=18.5} {
        set Kro [expr {-0.00106188*pow($ro,4) + 0.0397881*pow($ro,3) - 0.412655*pow($ro,2) + 0.210616*$ro + 12}]
      } else {
        set Kro 2.0
      }
    }
    1.35 {

    }
    1.36 {
      if {$ro<=1} {
        set Kro [expr {0.120168*pow($ro,3.93842)}]
      } elseif {$ro<=5.3} {
        set Kro [expr {0.00768577*pow($ro,4) - 0.165079*pow($ro,3) + 1.02312*pow($ro,2) - 1.28862*$ro + 0.540725}]
      } elseif {$ro<=11.8} {
        set Kro [expr {-0.00308238*pow($ro,4) + 0.137378*pow($ro,3) - 2.09913*pow($ro,2) + 12.831*$ro - 23.1115}]
      } elseif {$ro<=21} {
        set Kro [expr {0.000027275482*pow($ro,6) - 0.003041112*pow($ro,5) + 0.13968682*pow($ro,4) - 3.3689908*pow($ro,3) + 44.832387*pow($ro,2) - 311.1964*$ro + 880.85479}]
      } else {
        set Kro 2.0
      }
    }
    1.37 {
#=ЕСЛИ(C2<2.15;-0.0129966076*C2^4 + 0.128562512*C2^3 + 0.0518135551*C2^2 - 0.059251041*C2^1+ 0.01;ЕСЛИ(C2<3.95;0.091452806*C2^5 - 1.1065935*C2^4 + 4.78874386*C2^3 - 8.23918147*C2^2 + 3.90927863*C2^1 + 2.69560872;ЕСЛИ(C2<5.15;3.85854759*C2^5 - 86.9811652*C2^4 + 781.731199*C2^3 - 3501.52894*C2^2 + 7817.9757*C2^1 - 6958.91171;ЕСЛИ(C2<6.45;-4.26441822*C2^5 + 122.557357*C2^4 - 1405.60888*C2^3 + 8041.2936*C2^2 - 22946.0452*C2^1 + 26130.8803;ЕСЛИ(C2<12.45;0.000183026034*C2^6 - 0.0111129479*C2^5 + 0.272005152*C2^4 - 3.42648136*C2^3 + 23.4705729*C2^2 - 83.8086735*C2^1 + 127.508413;ЕСЛИ(C2<24;0.0000436888904*C2^6 - 0.004871325*C2^5 + 0.222373081*C2^4 - 5.31216682*C2^3 + 69.9519403*C2^2 - 481.011336*C2^1+ 1351.25238;2))))))
      if {$ro<=2.15} {
        set Kro                                                     [expr { -0.0129966076*pow($ro,4) + 0.128562512*pow($ro,3) + 0.0518135551*pow($ro,2) - 0.059251041*$ro + 0.01000000}]
      } elseif {$ro<=3.95} {
        set Kro                            [expr {  0.0914528060*pow($ro,5) - 1.106593500*pow($ro,4) + 4.788743860*pow($ro,3) - 8.2391814700*pow($ro,2) + 3.909278630*$ro + 2.69560872}]
      } elseif {$ro<=5.15} {
        set Kro                            [expr {  3.8585475900*pow($ro,5) - 86.98116520*pow($ro,4) + 781.7311990*pow($ro,3) - 3501.5289400*pow($ro,2) + 7817.975700*$ro - 6958.91171}]
      } elseif {$ro<=6.45} {
        set Kro                            [expr { -4.2644182200*pow($ro,5) + 122.5573570*pow($ro,4) - 1405.608880*pow($ro,3) + 8041.2936000*pow($ro,2) - 22946.04520*$ro + 26130.8803}]
      } elseif {$ro<=12.45} {
        set Kro [expr {0.0001830260340*pow($ro,6) - 0.0111129479*pow($ro,5) + 0.272005152*pow($ro,4) - 3.426481360*pow($ro,3) + 23.470572900*pow($ro,2) - 83.80867350*$ro + 127.508413}]
      } elseif {$ro<=24} {
        set Kro [expr {0.0000436888904*pow($ro,6) - 0.0048713250*pow($ro,5) + 0.222373081*pow($ro,4) - 5.312166820*pow($ro,3) + 69.951940300*pow($ro,2) - 481.0113360*$ro + 1351.25238}]
      } else {
        set Kro 2.0
      }
    }
  }
  return $Kro
}

proc Fr {f} {

#ЕСЛИ(D2<0.48;0.75;ЕСЛИ(D2<2.3;-0.00288527*D2^6-0.0422401*D2^5+0.452731*D2^4-1.53055*D2^3+2.44021*D2^2-2.09615*D2+1.283;ЕСЛИ(D2<3.7;-0.317406*D2^5+4.84797*D2^4-29.4644*D2^3+89.0634*D2^2-133.959*D2+80.4856;ЕСЛИ(D2<6.05;-0.00424958*D2^5+0.105528*D2^4-1.04762*D2^3+5.19503*D2^2-12.8854*D2+12.9121;ЕСЛИ(D2<6.33;-1327.3160950541*D2^6+49172.4319150115*D2^5-758991.903342618*D2^4+6247850.20147686*D2^3-28928492.2478744*D2^2+71432991.1232234*D2-73491933.3982535;0.0169)))))
  if {$f<0.48} {
    set r 0.75
  } elseif {$f<2.25} {
    set r [expr {-0.00288527*pow($f,6)-0.0422401*pow($f,5)+0.452731*pow($f,4)-1.53055*pow($f,3)+2.44021*pow($f,2)-2.09615*$f+1.283}]
  } elseif {$f<3.3} {
    set r [expr {-0.317406*pow($f,5)+4.84797*pow($f,4)-29.4644*pow($f,3)+89.0634*pow($f,2)-133.959*$f+80.4856}]
  } elseif {$f<4.2} {
    set r [expr {-2.8693890E-03*pow($f,4) + 4.3561849E-02*pow($f,3) - 2.1171906E-01*pow($f,2) + 2.7123339E-01*$f + 3.6160483E-01}]
#(3.68 3.7) set r [expr {-0.9881283*$f + 3.7799889}]
  } elseif {$f<6.05}  {
    set r [expr {-0.00424958*pow($f,5)+0.105528*pow($f,4)-1.04762*pow($f,3)+5.19503*pow($f,2)-12.8854*$f+12.9121}]
  } elseif {$f<6.33}  {
    set r [expr {-1327.3160950541*pow($f,6)+49172.4319150115*pow($f,5)-758991.903342618*pow($f,4)+6247850.20147686*pow($f,3)-28928492.2478744*pow($f,2)+71432991.1232234*$f-73491933.3982535}]
  } else {
    set r 0.0169
  }
# 3.3 4.2 set r [expr {-2.8693890E-03*pow($f,4) + 4.3561849E-02*pow($f,3) - 2.1171906E-01*pow($f,2) + 2.7123339E-01*$f + 3.6160483E-01}]
  return $r
}

proc FindR {f} {
global wms

  switch $wms(calibr) {
    "1" {
      if {$f<=0.6} {

        set r 0.88
      } else {
        set r [expr {-0.0022672*pow($f,5) + 0.0405949*pow($f,4) - 0.2791642*pow($f,3) + 0.9393928*pow($f,2) - 1.6628390*$f + 1.5102498}]
      }
    }
    "2" {
      if {$f<=0.72} {

        set r 0.6
      } else {

        set r [expr {-0.0037652*pow($f,3) + 0.0642649*pow($f,2) - 0.3793503*$f + 0.8370446}]
      }
    }
    "3" {
      if {$f<=1.35} {

        set r 0.43
      } else {
        set r [expr {-0.0064821*pow($f,3) + 0.0943902*pow($f,2) - 0.4842251*$f + 0.9241477}]
      }
    }
    "4" {
      if {$f<=1.33} {

        set r 0.43
      } else {
        set r [expr {-0.0067849*pow($f,3) + 0.0972538*pow($f,2) - 0.4906239*$f + 0.9219220}]
      }
    }
    "5" {
      if {$f<=1.45} {

        set r 0.214
      } else {
        set r [expr { 0.0011971*pow($f,4) - 0.0209825*pow($f,3) + 0.1405575*pow($f,2) - 0.4482630*$f + 0.6273621}]
      }
    }
    "6" {
      if {$f<=1.352} {

        set r 0.626
      } elseif {$f<=1.589} {

        set r [expr {3.7909386*pow($f,2) - 13.0918261*$f + 11.3965306}]
      } elseif {$f<=6.1} {

        set r [expr {-0.0010636*pow($f,5) + 0.0217152*pow($f,4) - 0.1737817*pow($f,3) + 0.6870908*pow($f,2) - 1.3733011*$f + 1.1821632}]
      } else {
        set r 0
      }
    }
    "7" {
      if {$f<=1.352} {
        set r [expr {-2.23069*pow($f,4) + 7.52743*pow($f,3) - 8.90548E+00*pow($f,2) + 3.80223*$f + 0.6}]
#        set r [expr {0.00853346*pow($f,6) - 0.203521*pow($f,5) + 1.95833*pow($f,4) - 9.69482*pow($f,3) + 25.9488*pow($f,2) - 35.511*$f + 19.4551}]
      } elseif {$f<=1.589} {

        set r [expr {3.7909386*pow($f,2) - 13.0918261*$f + 11.3965306}]
      } elseif {$f<=6.1} {

        set r [expr {-0.0008320*pow($f,5) + 0.0170449*pow($f,4) - 0.1377462*pow($f,3) + 0.5567398*pow($f,2) - 1.1539553*$f + 1.0450021}]
      } else {
        set r 0.02945
      }
    }
    8 {

    }
    9 {

    }
  }
  return $r
}

proc FindKro {ro} {
global wms

  set Kro 2.0
  switch $wms(calibr) {
    1 {
      if {$ro<=2} {

        set Kro [expr {0.1377676*pow($ro,2) - 0.0704958*$ro}]
      } elseif {$ro<=13} {

        set Kro [expr {-0.0003450*pow($ro,5) + 0.0138103*pow($ro,4) - 0.1946504*pow($ro,3) + 1.0762910*pow($ro,2) - 1.4915751*$ro + 0.7516198}]
      } else {
        set Kro 2.0
      }
    }
    2 {
      if {$ro<=2.24} {

        set Kro [expr {0.2897308*pow($ro,2) - 0.2543732*$ro + 0.0564320}]
      } elseif {$ro<=9} {

        set Kro [expr {0.0049246332*pow($ro,4) - 0.1132932308*pow($ro,3) + 0.7469502813*pow($ro,2) - 0.8580563892*$ro + 0.2649464670}]
      } else {
        set Kro 2.0
      }
    }
    3 {
      if {$ro<=8.9} {

        set Kro [expr {0.0003439*pow($ro,5) - 0.0034079*pow($ro,4) - 0.0356999*pow($ro,3) + 0.4069800*pow($ro,2) - 0.2802806*$ro + 0.0390195}]
      } else {
        set Kro 2.0
      }
    }
    4 {
      if {$ro<=14} {
        set Kro [expr {0.0016617*pow($ro,4) - 0.0451815*pow($ro,3) + 0.3227773*pow($ro,2) - 0.1248829*$ro + 0.0141796 }]
      } else {
        set Kro 2.0
      }
    }
    5 {
      if {$ro<=1.7} {

        set Kro [expr {-0.1509419*pow($ro,3) + 0.6724052*pow($ro,2) - 0.3076015*$ro + 0.0410838}]
      } elseif {$ro<=16} {

        set Kro [expr {-0.0000102*pow($ro,6) + 0.0005750*pow($ro,5) - 0.0124789*pow($ro,4) + 0.1292215*pow($ro,3) - 0.6673825*pow($ro,2) + 1.9391020*$ro - 1.1637845}]
      } else {
        set Kro 2.0
      }
    }
    6 {
      if {$ro<=0.9} {

        set Kro [expr {-0.1425502*pow($ro,3) + 0.5847755*pow($ro,2) - 0.1686130*$ro + 0.0142218}]
      } elseif {$ro<=10} {

        set Kro [expr {-0.0010618*pow($ro,4) + 0.0192961*pow($ro,3) - 0.1257411*pow($ro,2) + 0.7062750*$ro - 0.3014073}]
      } else {
        set Kro 2.0
      }
    }
    7 {
      if {$ro<=0.9} {

        set Kro [expr {-0.1425502*pow($ro,3) + 0.5847755*pow($ro,2) - 0.1686130*$ro + 0.0142218}]
      } elseif {$ro<=10} {

        set Kro [expr {-0.0010618*pow($ro,4) + 0.0192961*pow($ro,3) - 0.1257411*pow($ro,2) + 0.7062750*$ro - 0.3014073}]
      } else {
        set Kro 2.0
      }
    }
    8 {

    }
    9 {

    }
  }
  return $Kro
}

proc FormOldWMS {name file} {
global wms mff

  if {$wms($name,type)=="txt"} {
    set fn ${name}
  } else {
    set fn ${name}_$wms($name,type)
  }

  set of [open "$file/${fn}.txt"]
  set data [read $of]
  close $of

  set lines [split $data \n]

  set flag 0
  set cnt 0
  set cnt3 0
  set reads 1
  set mff($name,new_meth) 0
  set mff($name,coord_in_tube) 2

  foreach str $lines {
    if {[llength $str]>0} {
      if {!$flag} {
        if {$cnt==0} {
          set s [split $str " :;"]

          if {$wms($name,type)=="txt"} {set wms($name,type) [lindex $s end-1]}

          set mff($name,Io,cntlist) {}
          set mff($name,coef) {}
          set mff($name,2w,blu) $wms($name,2w,blu)
          set mff($name,2w,red) $wms($name,2w,red)

          set mff($name,RWI)    $wms($name,RWI)
          set mff($name,RTI)    $wms($name,RTI)
          set mff($name,RC)     $wms($name,RC)
          set mff($name,RH)     $wms($name,RH)
          set mff($name,ALFAI)  $wms($name,ALFAI)

          incr cnt
        }
        if {[lsearch $str "Join=*"]!=-1} {
          set b [lindex [split [lindex $str 0] =] 1]
          set mff($name,Io1) [string range $b 0 0]
          set mff($name,Io2) [string range $b end end]
        }
        if {[lsearch $str "NewMeth=*"]!=-1} {
          set b [lindex [split [lindex $str 0] =] 1]
          set mff($name,new_meth) [string range $b 0 0]
        }
        if {[lsearch $str "XinTube=*"]!=-1} {
          set b [lindex [split [lindex $str 0] =] 1]
          set mff($name,coord_in_tube) [string range $b 0 0]
        }
        if {[lsearch $str "L(мм)=*"]!=-1} {
          set b [split $str ";"]
          set d [split [lindex $b 1] =]
          set mff($name,L) [lindex $d 1]
          set d [split [lindex $b 2] =]
          set mff($name,repeat) [lindex $d 1]
        }
        if {[lsearch $str "RWI*"]!=-1} {
          set b [split $str ";"]
          foreach item $b {
            set d [split $item =]
            set p1 [eval list [lindex $d 0]]
            set p2 [lindex $d 1]
            if {$p1=="blu" || $p1=="red"} {
              set mff($name,2w,$p1) $p2
            } else {
              set mff($name,$p1) $p2
            }
          }
        }
        if {[lsearch $str "K(*"]!=-1} {
          set k [split $str ";"]
          foreach item $k {
            if {[llength $item]>0} {
              set kk [split $item "=()"]
              lappend mff($name,coef) [lindex $kk 3]
            }
          }
        }
      }

      set str [concat $str]
      if {[lindex $str 0]=="hh:mm:ss"} {
        set flag 1
        set a [expr {[lsearch $str "T,*"]+1}]
        set mff($name,lamda) [lrange $str $a end]
        set cnt4 0
        set flag2 0
        set flag3 0
        set mff($name,red,index) -1
        set mff($name,blu,index) -1

        if {[llength $mff($name,lamda)]<11} {
          set d 40000
        } elseif {[llength $mff($name,lamda)]<200} {
          set d 3500
        } else {
          set d 500
        }
        set minblu [expr {$mff($name,2w,blu) - $d}]
        set maxblu [expr {$mff($name,2w,blu) + $d}]
        set minred [expr {$mff($name,2w,red) - $d}]
        set maxred [expr {$mff($name,2w,red) + $d}]

        foreach item $mff($name,lamda) {
          if {$item>=$minblu && $item<=$maxblu} {
             set mff($name,blu,index) $cnt4
             set mff(oldblu) $item
             incr flag2
          } elseif {$item>$minred && $item<$maxred} {
             set mff($name,red,index) $cnt4
             set mff(oldred) $item
             incr flag3
          } elseif {$flag2 && $flag3} {
            break
          }
          incr cnt4
        }
      }

      if {$flag && [lindex $str 0]!="hh:mm:ss"} {
        if {$cnt3==[expr {3+3*$mff($name,Io1)+3*$mff($name,Io2)}]} {
          incr reads
          set cnt3 0
        }

        if {$cnt3==0} {
          set mff($name,time,$reads) [lindex $str 0]
          set mff($name,Dens,$reads) [lindex $str 5]
          set mff($name,temp,$reads) [lindex $str 8]
          set mff(x,$reads) [lindex $str 3]
          set mff(y,$reads) [lindex $str 4]
          if {$mff(x,$reads)<$mff($name,coord_in_tube)} {

            lappend mff($name,Io,cntlist) $reads
          }
        }
        set Join [lindex $str [expr {$a-3}]]
        set Type [lindex $str [expr {$a-2}]]
        set I_lst [lrange $str $a end]

        if {$Type=="Iразв"} {
          set wet 1
          if {[lindex $I_lst 0]==1 || [lindex $I_lst 0]==0} {set wet 0}
          if {![info exists wms($name,wet,$reads)]} {
            set wms($name,wet,$reads) $wet
          }
        }
        set mff($name,$Type,$Join,$reads) $I_lst
        set Bcur 0
        if {$wms($name,type)=="swms"} {
          foreach i {0 1 2 3 end-5 end-4 end-3 end-2 end-1 end} {
            set Bcur [expr {$Bcur+[lindex $I_lst $i]}]
          }
          set Bcur [expr {$Bcur/10.}]
          set IB_lst {}
          foreach item $I_lst {
            lappend IB_lst [expr {$item - $Bcur}]
          }
        } else {
          set IB_lst $I_lst
        }
        set mff($name,$Type,$Join,$reads) $IB_lst
        incr cnt3
      }
      set mff(end) $reads
    }
  }
  catch [file mkdir $file/Temp]

  set mf(temp) [open $file/Temp/MEAS_[string range $name 1 end].dat "w"]
  set mf(wms) [open $file/MEAS_[string range $name 1 end].dat "w"]

  for {set reads 1} {$reads<=$mff(end)} {incr reads} {

## Calculate Io
    if {$mff($name,new_meth)} {
      set i 0
      foreach lamda $mff($name,lamda) {
        set cnt 1
        foreach rds "[lindex $mff($name,Io,cntlist) 0] [lindex $mff($name,Io,cntlist) end]" {

          set a4 [expr {1.*([lindex $mff($name,Iсв1,1,$rds) $i] - [lindex $mff($name,Bcur,1,$rds) $i])}]
          set Ref [expr {1.*([lindex $mff($name,Ref,1,$rds) $i] - [lindex $mff($name,Bcur,1,$rds) $i])}]
          if {$Ref!=0} {set a4 [expr {$a4/$Ref}]}
          set Io1 [expr {[lindex $mff($name,coef) $i]*$a4}]

          if {$mff($name,Io2)} {
            set a5 [expr {1.*([lindex $mff($name,Iсв2,2,$rds) $i] - [lindex $mff($name,Bcur,2,$rds) $i])}]
            set Ref [expr {1.*([lindex $mff($name,Ref,2,$rds) $i] - [lindex $mff($name,Bcur,2,$rds) $i])}]
            if {$Ref!=0} {set a5 [expr {$a5/$Ref}]}
            set Io2 [expr {[lindex $mff($name,coef) $i]*$a5}]
          } else {
            set Io2 $Io1
          }

          set Io [expr {($Io2 + $Io1)/2.}]

          if {$cnt==1} {
            set Io_1 $Io
          } else {
            set Io_2 $Io
          }
          incr cnt
        }
        lappend mff($name,Io_1) $Io_1
        lappend mff($name,Io_2) $Io_2
        incr i
      }
    } elseif {$mff($name,Io1) || $mff($name,Io2) } {
      set i 0
      foreach lamda $mff($name,lamda) {
        if {!$mff($name,Io1)} {
          set Io1 0
        } else {
          set a4 [expr {1.*([lindex $mff($name,Iсв1,1,$reads) $i] - [lindex $mff($name,Bcur,1,$reads) $i])}]
          set Ref [expr {1.*([lindex $mff($name,Ref,1,$reads) $i] - [lindex $mff($name,Bcur,1,$reads) $i])}]
          if {$Ref!=0} {set a4 [expr {$a4/$Ref}]}
          set Io1 [expr {[lindex $mff($name,coef) $i]*$a4}]
          if {!$mff($name,Io2)} {
            set Io2 $Io1
          }
        }
        if {$mff($name,Io2)} {
          set a5 [expr {1.*([lindex $mff($name,Iсв2,2,$reads) $i] - [lindex $mff($name,Bcur,2,$reads) $i])}]
          set Ref [expr {1.*([lindex $mff($name,Ref,2,$reads) $i] - [lindex $mff($name,Bcur,2,$reads) $i])}]
          if {$Ref!=0} {set a5 [expr {$a5/$Ref}]}
          set Io2 [expr {[lindex $mff($name,coef) $i]*$a5}]
          if {!$mff($name,Io1)} {
            set Io1 $Io2
          }
        }
        lappend mff($name,Io1,$reads) $Io1
        lappend mff($name,Io2,$reads) $Io2
        incr i
      }
    } else {
      set mff($name,Io_1) {}
      set mff($name,Io_2) {}
      set i 0
      foreach lamda $mff($name,lamda) {
        set cnt 1
        foreach rds "[lindex $mff($name,Io,cntlist) 0] [lindex $mff($name,Io,cntlist) end]" {
          set a2 [expr {[lindex $mff($name,Iразв,0,$rds) $i] - [lindex $mff($name,Bcur,0,$rds) $i]}]
          set Ref [lindex $mff($name,Ref,0,$rds) $i]
          if {$Ref!=0} {set a2 [expr {1.*$a2/$Ref}]}
          if {$cnt==1} {
            set Io_1 $a2
          } else {
            set Io_2 $a2
          }
          incr cnt
        }
        lappend mff($name,Io_1) $Io_1
        lappend mff($name,Io_2) $Io_2
        incr i
      }
    }
  }
## Calculate I
  for {set reads 1} {$reads<=$mff(end)} {incr reads} {
    set i 0
    set mff($name,I,$reads) {}
    foreach lamda $mff($name,lamda) {
      set a3 [expr {1.*([lindex $mff($name,Iразв,0,$reads) $i] - [lindex $mff($name,Bcur,0,$reads) $i])}]
      set Ref [expr {1.*([lindex $mff($name,Ref,0,$reads) $i] - [lindex $mff($name,Bcur,0,$reads) $i])}]
      if {$Ref!=0} {set a3 [expr {1.*$a3/$Ref}]}
      lappend mff($name,I,$reads) $a3
      incr i
    }

    set red $mff($name,red,index)
    set blu $mff($name,blu,index)

    set mff(I_blu,$reads)   [lindex $mff($name,I,$reads) $blu]
    set mff(I_red,$reads)   [lindex $mff($name,I,$reads) $red]

    if {($mff($name,Io1) || $mff($name,Io2)) && !$mff($name,new_meth)} {
      set mff(I_blu01,$reads) [lindex $mff($name,Io1,$reads) $blu]
      set mff(I_blu02,$reads) [lindex $mff($name,Io2,$reads) $blu]
      set mff(I_red01,$reads) [lindex $mff($name,Io1,$reads) $red]
      set mff(I_red02,$reads) [lindex $mff($name,Io2,$reads) $red]
    } else {

      set mff(I_blu01,$reads) [lindex $mff($name,Io_1) $blu]
      set mff(I_blu02,$reads) [lindex $mff($name,Io_2) $blu]
      set mff(I_red01,$reads) [lindex $mff($name,Io_1) $red]
      set mff(I_red02,$reads) [lindex $mff($name,Io_2) $red]
    }

    foreach item {temp wms} {
      if {$item!="wms" || $wms($name,wet,$reads)} {
        if {$item=="wms" || $mff(x,$reads)>=$mff($name,coord_in_tube} {
          puts -nonewline $mf($item) "$mff($name,time,$reads)"
          puts $mf($item) " [format "%11.4f" $mff(I_blu01,$reads)]	[format "%11.4f" $mff(I_red01,$reads)]	[format "%11.4f" $mff(I_blu,$reads)]	[format "%11.4f" $mff(I_red,$reads)]	[format "%11.4f" $mff(I_blu02,$reads)]	[format "%11.4f" $mff(I_red02,$reads)]	[format "%11.4f" $mff($name,temp,$reads)]"
          puts $mf($item) ""
        }
      }
    }
  }

  foreach item {temp wms} {
    puts -nonewline $mf($item) "\# $mff($name,repeat)"
    foreach par {L RWI RTI RC RH ALFAI} {
      puts -nonewline $mf($item) " $mff($name,$par)"
    }
    if {$item=="temp"} {
      set kk 3345
    } else {
      set kk 3343
    }

    puts -nonewline $mf($item) " $kk [lindex $mff($name,coef) $mff($name,red,index)] [lindex $mff($name,coef) $mff($name,blu,index)]"
    puts -nonewline $mf($item) " $mff($name,2w,red) $mff($name,2w,blu)"
    puts $mf($item) ""

    for {set i 1} {$i<=$mff(end)} {incr i} {
      if {$item!="wms" || $wms($name,wet,$i)} {
        if {$item=="wms" || $mff(x,$i)>=$mff($name,coord_in_tube} {
          puts $mf($item) "[format "%3.0f" $mff(x,$i)] [format "%3.0f" $mff(y,$i)] $mff($name,Dens,$i)"
        }
      }
    }
    close $mf($item)
  }
}