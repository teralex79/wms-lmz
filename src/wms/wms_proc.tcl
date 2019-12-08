proc SetConfZond {name} {
global wms meas

  catch {
    destroy .pr$name
  }

  if {$wms($name,active)} {

    toplevel .pr$name
    wm title .pr$name "Настройки $name"
    wm geometry .pr$name "=+450+250"
    wm protocol .pr$name WM_DELETE_WINDOW "ReadIni;set wms($name,active) 0; destroy .pr$name"
    focus .pr$name

    set fr [frame .pr$name.fr1 -width 60]
    grid $fr -row 0 -column 0 -sticky news -padx 2 -pady 2

    label $fr.title00 -text "Зонды" -width 8 -anchor w
    grid $fr.title00 -row 0 -column 0 -sticky nw
    label $fr.01 -text "$name" -width 8 -anchor w
    grid $fr.01 -row 0 -column 1 -sticky nw
    label $fr.title10 -text "type" -width 8 -anchor w
    grid $fr.title10 -row 1 -column 0 -sticky nw
#    ComboBox $fr.11 -textvariable wms($name,type) -width 8 -justify center  -relief ridge -values {swms} -command "SetConfZond $name" -state disabled
    entry $fr.11 -textvariable wms($name,type) -width 8 -justify center  -state disabled
    grid $fr.11 -row 1 -column 1  -sticky nw

    set cnt1 2

    set adrDev $wms($name,adrDev)

    switch $wms($name,type) {

      "swms" {
        set lst {Adr_Moxa Port_swms Port_adam Adr_adam PixMode IntTime SName l0 l1 l2 l3 InitSpec Run}

        foreach item $lst {
          label $fr.title${cnt1}0 -text "$item" -width 10 -anchor w -relief ridge
          grid $fr.title${cnt1}0 -row $cnt1 -column 0 -sticky nw
          incr cnt1
        }

        set cnt2 1
        set cnt1 2
        foreach item $lst {
          if {[string range $item 0 3]=="Port"} {

            set type [string range $item 5 end]
            set item "port"
          }
          switch $item {

            "Adr_Moxa" {ComboBox $fr.$cnt1$cnt2 -width 13 -textvariable wms($name,adr,moxa)\
                        -values {192.168.0.123 192.168.0.124} -justify right}
            "port"     {ComboBox $fr.$cnt1$cnt2 -width 13 -textvariable wms($name,port,$type)\
                        -values {4001 4002 4003 4004} -justify right}
            "Adr_adam"      {ComboBox $fr.$cnt1$cnt2 -textvariable wms($name,adr,adam) -width 8 -justify right\
                        -values {0 1 2 3 4 5 6 7 8 9} -command "Valid1 $name" -modifycmd "Valid1 $name"}
            "Run" {

              button $fr.${cnt1}$cnt2 -text "$item" -width 10 -anchor w -command "SaveProp; SetMethod $name; RunAdam $name; runSWMS $name;AddMZ $name; destroy .pr$name"
            }
            "InitSpec" {

              button $fr.${cnt1}$cnt2 -text "$item" -width 10 -anchor w -command "runSWMS $name"
            }
            "Meas" {

              button $fr.${cnt1}$cnt2 -text "$item" -width 10 -anchor w -command "Meas_SWMS $name 0 k"
            }
            "IntTime" {entry $fr.$cnt1$cnt2 -textvariable wms($name,swms,$item) -justify right -width 13}
            "PixMode" {ComboBox $fr.$cnt1$cnt2 -width 11 -textvariable wms($name,swms,$item)\
                      -values {0 1 3 4} -justify right -state disabled}
            "default" {label $fr.$cnt1$cnt2 -textvar wms($name,swms,$item) -relief ridge -width 13 -anchor w}
          }
          grid $fr.$cnt1$cnt2 -row $cnt1 -column $cnt2 -sticky nw
          incr cnt1
        }
        incr cnt2
      }
    }
  } else {
    set a [lsearch -exact $wms(zond) $name]
    set wms(zond) [lreplace $wms(zond) $a $a]
    AddMZ $name
    if {$wms($name,type)=="swms"} {
      runSWMS $name
    }
  }
}

proc AddMZ {name} {
global wms meas

  if {$wms($name,active)} {
    if {[lsearch -exact $wms(zond) $name]==-1} {

      lappend wms(zond) $name
      set wms($name,firstpoint) 1
      set wms(zondinit) 0
      set wms(points) 0
    }
  } else {

    set a [lsearch -exact $wms(zond) $name]
    set wms(zond) [lreplace $wms(zond) $a $a]
  }

  ReadIni
  set zond ".fr1.zond"

  catch [eval destroy [winfo child $zond]]
  after 100
  .fr1.zond configure -width 1

  if {[llength $wms(zond)]>0} {

    label $zond.title00 -text "Зонды" -width 12 -anchor nw -relief ridge
    grid $zond.title00 -row 0 -column 0 -sticky news

    label $zond.title10 -text "Цвет" -width 12 -anchor nw -relief ridge
    grid $zond.title10 -row 1 -column 0 -sticky news

    set cnt2 1
    set meascoef 0
    foreach nm $wms(zond) {

      set adrDev $wms($nm,adrDev)

      set nmbwidth($nm) 0

      set wms($nm,colorlist) "Spectrum"
      incr nmbwidth($nm)
      set wdth($nm)  31
      set wdth1($nm) 31
      set wdth2($nm) 18
      set wdth3($nm) 15
    }

    foreach nm $wms(zond) {

      set adrDev $wms($nm,adrDev)

      set fr [labelframe $zond.title0$cnt2]
      grid $fr -row 0 -column $cnt2 -sticky news

      label $fr.lb$nm -text "$nm" -height 1 -bg green
      pack  $fr.lb$nm -side top -fill both

      set fr [frame $zond.title1$cnt2]
      grid $fr  -row 1 -column $cnt2 -sticky news

      foreach ch $wms($nm,$wms($nm,type),sortchlst) {

        label $fr.spec -text "spectrum" -width [expr {round(ceil($wdth($nm)/$nmbwidth($nm)))}] -anchor center -relief ridge
        pack  $fr.spec -side left -fill both
      }
      incr cnt2

      if {$wms($nm,Io1) || $wms($nm,Io2)} {

        set meascoef 1
      }
    }

    set cnt1 2

    foreach item {coef Iсв1 I Iсв2 "I/Io" "Темн.Ток" "Опора" t WMS_cmd state R ang "ост.точек" "изм.точка" Type} {

      set flag 1

      if {$item=="coef" && !$meascoef} {
         set flag 0
      }

      if {$flag} {
        label $zond.title${cnt1}0 -text "$item" -width 12 -anchor w -relief ridge
        grid $zond.title${cnt1}0 -row $cnt1 -column 0  -sticky nw
      }
      incr cnt1
    }

    set cnt1 2

    foreach item {coef Io1 I Io2 IIo bcur ref t cmd state tr ang points firstpoint type} {

      set cnt2 1
      set cnt3 0
      set flag 1

      if {$item=="coef" && !$meascoef} {set flag 0}

      if {$flag} {
        foreach nm $wms(zond) {
          if {[llength $wms($nm,colorlist)]>3} {
            set a [expr {[llength $wms($nm,colorlist)]-2}]
          } else {
            set a 1.0
          }

          if {$cnt1<7} {

            set fr [frame $zond.title$cnt1$cnt2]
            grid $fr -row $cnt1 -column $cnt2 -sticky news
            set cnt4 0
            foreach clr $wms($nm,colorlist) {
              if {$item=="coef"} {
                button $fr.[string tolower $clr] -text "Коэффициенты" -width $wdth($nm) -command "EditCoefSWMS $nm"
                grid   $fr.[string tolower $clr] -row $cnt3 -column $cnt4  -sticky news
              } else {
                label $fr.[string tolower $clr] -textvariable wms($nm,$item,$clr) -width $wdth1($nm) -justify right -relief ridge
                grid  $fr.[string tolower $clr] -row $cnt3 -column $cnt4  -sticky news
              }
              incr cnt4
            }
            incr cnt3
          } elseif {$item=="tr" || $item=="ang"} {

            set fr [frame $zond.$cnt1$cnt2]
            grid $fr -row $cnt1 -column $cnt2 -sticky news

            entry $fr.en$item -textvariable wms($nm,$item,next) -width $wdth2($nm) -state disable -justify right
            grid $fr.en$item -row 0 -column 0 -sticky news

            label $fr.lb$item -textvariable wms($nm,$item,current) -width $wdth3($nm) -justify right -relief ridge
            grid $fr.lb$item -row 0 -column 1 -sticky news
          } elseif {$item=="state"} {

            set fr [frame $zond.$cnt1$cnt2]
            grid $fr -row $cnt1 -column $cnt2 -sticky news

            label $fr.en$item -textvariable wms($nm,$item,next) -width $wdth3($nm) -justify right -relief ridge
            grid $fr.en$item -row 0 -column 0 -sticky news

            label $fr.lb$item -textvariable wms($nm,$item,current) -width $wdth3($nm) -justify right -relief ridge
            grid $fr.lb$item -row 0 -column 1 -sticky news
          } elseif {$item=="type"} {

            label $zond.type$nm -text $wms($nm,$item) -font {TimesNewRoman 10 bold} -justify right -relief ridge
            grid $zond.type$nm -row $cnt1 -column $cnt2 -sticky news
          } elseif {$item=="cmd"} {

            label $zond.cmd$nm -textvariable wms($nm,$item) -font {TimesNewRoman 10 bold} -justify right -relief ridge
            grid $zond.cmd$nm -row $cnt1 -column $cnt2 -sticky news
          } else {

            label $zond.$cnt1$cnt2 -textvariable wms($nm,$item) -justify right -relief ridge
            grid $zond.$cnt1$cnt2 -row $cnt1 -column $cnt2 -sticky news
          }
          incr cnt2 1
        }
      }
      incr cnt1
    }

    set cnt2 1

    foreach nm $wms(zond) {
      ReadRWV $nm

      set fr [frame $zond.bottombt$nm]
      grid $zond.bottombt$nm -row $cnt1 -column $cnt2 -sticky nw

      button $fr.bt1 -text "Add point" -width 8 -command "AddPoint $nm"
      grid $fr.bt1 -row 0 -column 0 -sticky nw

      button $fr.bt2 -text "Add Graph" -width 8 -command "AddChart $nm"
      grid $fr.bt2 -row 0 -column 1 -sticky nw

      labelframe $fr.lf1 -text "No Wetness" -width 8
      grid $fr.lf1 -row 0 -column 2 -sticky nw
      checkbutton $fr.lf1.chbt1 -variable wms($nm,nowet) -justify right -anchor ne
      pack $fr.lf1.chbt1
      incr cnt2
    }

    ReadCoef $name

    .fr1.com.startlf.bt1 configure -state active
    .menu.init entryconfigure 0 -state active
    .menu.init entryconfigure 1 -state active
    .menu.options entryconfigure 0 -state active

  } else {
    .fr1.com.startlf.bt1 configure -state disable
    .menu.init entryconfigure 0 -state disable
    .menu.init entryconfigure 1 -state disable
    .menu.options entryconfigure 0 -state disable
  }

  AddChart $name
}

proc SetMethod {name} {
global wms

  switch $wms($name,meth) {
    "M1" {
       set wms($name,new_meth) 0
       set wms($name,Io1) 1
       set wms($name,Io2) 1
    }
    "M2" {
       set wms($name,new_meth) 0
       set wms($name,Io1) 0
       set wms($name,Io2) 0
    }
    "M3" {
       set wms($name,new_meth) 1
       set wms($name,Io1) 1
       set wms($name,Io2) 0
    }
  }
  FormInfo
}

proc Properties {} {
global wms rs meas

  catch {

    SaveProp
    ReadIni
    destroy .prop
  }
  
  toplevel .prop
  wm title .prop "Настройки"
  wm geometry .prop "=+450+250"
  wm protocol .prop WM_DELETE_WINDOW "ReadIni; destroy .prop"
  focus .prop
  set tnb [blt::tabnotebook .prop.nb -width 500 -takefocus 1 -samewidth no]
  grid $tnb -row 0 -column 0
  focus $tnb

  set ins 0
#  foreach item {"Общие" "Параметры" "New_WMS" "Spec_WMS" "Длины волн" "Коэффициенты"}
  foreach item {"Общие" "Параметры" "Spec_WMS" "Длины волн" "Коэффициенты"} {
    $tnb insert $ins -text $item
    incr ins
  }

###  "Общие"
  set ins 0

  set comn [frame .prop.nb.fr$ins -width 1520]
  grid $comn -row 0 -column 0 -sticky news -padx 2 -pady 2
  
  $tnb tab configure $ins -window $comn -fill both
  incr ins

    set row1 0
    set col1 0

    set alpha [labelframe $comn.alpha_old -text "Длинны волн старые"]
    grid $alpha -row $row1 -column $col1 -sticky nw -padx 2 -pady 2

      label $alpha.lbred -width 10 -text "Красный" -fg red -anchor w
      grid $alpha.lbred -row 0 -column 0 -sticky nw
      label $alpha.enred -width 5 -textvar wms(lamda,old,red) -justify right
      grid $alpha.enred -row 0 -column 1 -sticky nw

      label $alpha.lbblue -width 10 -text "Синий" -fg blue -anchor w
      grid $alpha.lbblue -row 1 -column 0 -sticky nw
      label $alpha.enblue -width 5 -textvar wms(lamda,old,blu) -justify right
      grid $alpha.enblue -row 1 -column 1 -sticky nw

    incr col1

    set param [labelframe $comn.param -text "Параметры"]
    grid $param -row $row1 -column $col1 -sticky nw -padx 2 -pady 2

      label $param.lbrpt -width 10 -text "Повторений" -anchor nw
      grid $param.lbrpt -row 0 -column 0 -sticky nw
      entry $param.enrpt -width 5 -textvar wms(repeat) -justify right
      grid $param.enrpt -row 0 -column 1 -sticky nw

      label $param.lbtlr -width 10 -text "Толеранс" -anchor nw
      grid $param.lbtlr -row 1 -column 0 -sticky nw
      entry $param.entlr -width 5 -textvar wms(tolerance) -justify right
      grid $param.entlr -row 1 -column 1 -sticky nw

      label $param.lbsens -width 10 -text "Чувств-ть" -anchor nw
      grid $param.lbsens -row 2 -column 0 -sticky nw
      entry $param.ensens -width 5 -textvar wms(sensetivity) -justify right
      grid $param.ensens -row 2 -column 1 -sticky nw

      label $param.lbclbr -width 10 -text "Калибровка" -anchor nw
      grid $param.lbclbr -row 3 -column 0 -sticky nw
      entry $param.enclbr -width 5 -textvar wms(calibr) -justify right
      grid $param.enclbr -row 3 -column 1 -sticky nw

      label $param.lbaver -width 10 -text "Оср_NWMS" -anchor nw
      grid $param.lbaver -row 4 -column 0 -sticky nw
      entry $param.enaver -width 5 -textvar wms(avermeas) -justify right
      grid $param.enaver -row 4 -column 1 -sticky nw

		incr row1
		set col1 0

    set path [labelframe $comn.path -text "Пути"]
    grid $path -row $row1 -column $col1 -sticky nw -columnspan 3 -padx 2 -pady 2

      label $path.lbdtpth -width 30 -text "Папка данных" -anchor w
      grid $path.lbdtpth -row 2 -column 0 -columnspan 2 -sticky nw
      entry $path.endtpth -width 30 -textvar wms(DATAPATH) -justify left
      grid $path.endtpth -row 3 -column 0 -sticky nw
      button $path.btdtpth -width 10 -text "Обзор" -command "ChooseDir $wms(DATAPATH) DATAPATH"
      grid $path.btdtpth -row 3 -column 1 -sticky nw

		incr row1

    set comment [labelframe $comn.cmnt -text "Комментарий"]
    grid $comment  -row $row1 -column $col1 -sticky nw -columnspan 3 -padx 2 -pady 2

      entry $comment.txt -width 30 -textvariable wms(comment)
      grid  $comment.txt -row 0 -column 0 -sticky nw

### "Параметры"

  set zond [frame .prop.nb.fr$ins]
  pack $zond

  $tnb tab configure $ins -window $zond -fill both
  incr ins
  
    set zond [frame $zond.fr]
    pack $zond -side top -anchor w

    label $zond.title00 -text "Зонды" -width 10 -anchor w
    grid $zond.title00 -row 0 -column 0 -sticky nw

    set cnt1 1

    foreach item {L RWI RTI RC RH ALFAI TEMPA TEMPB TEMPC "X in tube" "M1 with Join" "M2 w/o Join" "M3 New" Type} {

      label $zond.title${cnt1}0 -text "$item" -width 10 -anchor w
      grid $zond.title${cnt1}0 -row $cnt1 -column 0 -sticky nw
      incr cnt1
    }

    set cnt2 1

    foreach name $wms(zond) {

      label $zond.title0$cnt2 -text "$name" -width 10 -anchor w
      grid $zond.title0$cnt2 -row 0 -column $cnt2  -sticky nw
      incr cnt2
    }

    set cnt1 1

    foreach item {L RWI RTI RC RH ALFAI TEMPA TEMPB TEMPC coord_in_tube} {

      set cnt2 1
      if {$item=="L"} {
        set state normal
      } else {
        set state disable
      }

      foreach name $wms(zond) {

        entry $zond.$cnt1$cnt2 -textvariable wms($name,$item) -width 10 -justify right
        grid $zond.$cnt1$cnt2 -row $cnt1 -column $cnt2  -sticky nw
        incr cnt2
      }
      incr cnt1
    }

    foreach meth {M1 M2 M3} {
      set cnt2 1
      foreach name $wms(zond) {
        radiobutton $zond.$cnt1$cnt2 -variable wms($name,meth) -width 6 -value $meth -justify center -relief ridge -command "SetMethod $name"
        grid $zond.$cnt1$cnt2 -row $cnt1 -column $cnt2  -sticky news
        incr cnt2
      }
      incr cnt1
    }

    set cnt2 1
    
    foreach name $wms(zond) {
    
      entry $zond.$cnt1$cnt2 -textvariable wms($name,type) -width 6 -justify center -state disabled
      grid $zond.$cnt1$cnt2 -row $cnt1 -column $cnt2  -sticky news
      incr cnt2
    }
    incr cnt1

### SpecWMS

  set wmsn [frame .prop.nb.fr$ins]
  grid $wmsn -row 0 -column 0 -sticky nw

  $tnb tab configure $ins -window $wmsn -anchor nw
  incr ins

    set swms [frame $wmsn.fr]
    pack $swms -side top -anchor w

    label $swms.title00 -text "Зонды" -width 10 -anchor w -relief ridge
    grid $swms.title00 -row 0 -column 0 -sticky nw

    set cnt1 1

#    set lst {Adr_Moxa Port_swms Port_adam Adr_adam PixMode IntTime SName l0 l1 l2 l3 "" cntr ch InitSpec Meas}
    set lst {Adr_Moxa Port_swms Port_adam Adr_adam PixMode IntTime SName l0 l1 l2 l3 InitSpec Meas}
    foreach item $lst {

      label $swms.title${cnt1}0 -text "$item" -width 10 -anchor w -relief ridge
      grid $swms.title${cnt1}0 -row $cnt1 -column 0 -sticky nw
      incr cnt1
    }

    set cnt2 1
    foreach name $wms(zond) {
      set cnt1 0
      if {$wms($name,type)=="swms"} {
        foreach item [linsert $lst 0 name] {
          if {[string range $item 0 3]=="Port"} {

            set type [string range $item 5 end]
            set item "port"
          }
          switch $item {
            "name"    {label $swms.$cnt1$cnt2 -text "$name" -relief ridge -width 13 -anchor w}
            "Adr_Moxa" {ComboBox $swms.$cnt1$cnt2 -width 13 -textvariable wms($name,adr,moxa)\
                        -values {192.168.0.123 192.168.0.124} -justify right}
            "port"     {ComboBox $swms.$cnt1$cnt2 -width 13 -textvariable wms($name,port,$type)\
                        -values {4001 4002 4003 4004} -justify right}
            "Adr_adam"      {ComboBox $swms.$cnt1$cnt2 -textvariable wms($name,adr,adam) -width 8 -justify right\
                        -values {0 1 2 3 4 5 6 7 8 9} -command "Valid1 $name" -modifycmd "Valid1 $name"}
            "InitSpec" {

              button $swms.${cnt1}$cnt2 -text "$item" -width 10 -anchor w -command "runSWMS $name"
            }
            "Meas" {

              button $swms.${cnt1}$cnt2 -text "$item" -width 10 -anchor w -command "Meas_SWMS $name 0 k"
            }
            "IntTime" {entry $swms.$cnt1$cnt2 -textvariable wms($name,swms,$item) -justify right -width 13}
            "PixMode" {ComboBox $swms.$cnt1$cnt2 -width 11 -textvariable wms($name,swms,$item)\
                      -values {0 1 3 4} -justify right -state disabled}
            "cntr" {

              set fr1 [frame $swms.$cnt1$cnt2]

              ComboBox $fr1.tr -textvariable wms($name,$item,smc_tr) -width 3 -justify right -values {1 2}
              grid $fr1.tr -row 0 -column 0  -sticky news

              ComboBox $fr1.ang -textvariable wms($name,$item,smc_ang) -width 3 -justify right -values {1 2}
              grid $fr1.ang -row 0 -column 1  -sticky news

            }
            "ch" {

              set fr1 [frame $swms.$cnt1$cnt2]

              ComboBox $fr1.tr -textvariable wms($name,$item,smc_tr) -width 3 -justify right -values {1 2 3 4 5 6}
              grid $fr1.tr -row 0 -column 0  -sticky news

              ComboBox $fr1.ang -textvariable wms($name,$item,smc_ang) -width 3 -justify right -values {1 2 3 4 5 6}
              grid $fr1.ang -row 0 -column 1  -sticky news

            }
            "" {

              set fr1 [frame $swms.$cnt1$cnt2]

              label $fr1.tr -text "tr" -width 5 -relief ridge
              grid $fr1.tr -row 0 -column 0  -sticky nw

              label $fr1.ang -text "ang" -width 5 -relief ridge
              grid $fr1.ang -row 0 -column 1  -sticky nw
            }
            "default" {label $swms.$cnt1$cnt2 -textvar wms($name,swms,$item) -relief ridge -width 13 -anchor w}
          }
          grid $swms.$cnt1$cnt2 -row $cnt1 -column $cnt2 -sticky nw
          incr cnt1
        }
      }
      incr cnt2
    }

### "Длины волн"

  set wmsn [frame .prop.nb.fr$ins]
  grid $wmsn -row 0 -column 0 -sticky nw

  $tnb tab configure $ins -window $wmsn -anchor nw
  incr ins

  set rw 0
  set cl 0

  foreach name $wms(zond) {

    set swms [labelframe $wmsn.fr${name}1 -text "SWMS"]
    grid $swms -row $rw -column $cl -sticky news
    incr rw

    set cnt1 0
    set cnt2 0
    label $swms.title$cnt1$cnt2 -text "Зонд" -width 10 -anchor w
    grid $swms.title$cnt1$cnt2 -row $cnt1 -column $cnt2 -sticky nw
    incr cnt1
    label $swms.title$cnt1$cnt2 -text "l_uv" -width 10 -anchor w -relief ridge
    grid $swms.title$cnt1$cnt2 -row $cnt1 -column $cnt2  -sticky news
    incr cnt1
    label $swms.title$cnt1$cnt2 -text "l_ir" -width 10 -anchor w -relief ridge
    grid $swms.title$cnt1$cnt2 -row $cnt1 -column $cnt2  -sticky news
    incr cnt1
    label $swms.title$cnt1$cnt2 -text "npoint" -width 10 -anchor w -relief ridge
    grid $swms.title$cnt1$cnt2 -row $cnt1 -column $cnt2  -sticky news

    incr cnt2
    set cnt1 0

    label $swms.$cnt1$cnt2 -text "$name" -width 10 -anchor w -relief ridge
    grid $swms.$cnt1$cnt2 -row $cnt1 -column $cnt2  -sticky news
    incr cnt1
    ComboBox $swms.$cnt1$cnt2 -textvariable wms($name,l,uv) -width 6 -justify right -values $wms($name,swms,lamda)
    grid $swms.$cnt1$cnt2 -row $cnt1 -column $cnt2  -sticky news
    incr cnt1
    ComboBox $swms.$cnt1$cnt2 -textvariable wms($name,l,ir) -width 6 -justify right -values $wms($name,swms,lamda)
    grid $swms.$cnt1$cnt2 -row $cnt1 -column $cnt2  -sticky news
    incr cnt1
    entry $swms.$cnt1$cnt2 -textvariable wms($name,npoints) -width 8 -justify right
    grid $swms.$cnt1$cnt2 -row $cnt1 -column $cnt2  -sticky news
    incr cnt1


    set owms [labelframe $wmsn.fr${name}2 -text "2_wave"]
    grid $owms -row $rw -column $cl -sticky news
    incr cl
    set rw 0

    label $owms.title00 -text "Зонд" -width 10 -anchor nw
    grid $owms.title00 -row 0 -column 0 -sticky nw

    set cnt1 1

    foreach item {Color1 Color2} {

      label $owms.title${cnt1}0 -text "$item" -width 10 -anchor nw
      grid $owms.title${cnt1}0 -row $cnt1 -column 0 -sticky nw
      incr cnt1
    }

    set cnt2 1
    label $owms.title0$cnt2 -text "$name" -width 10 -anchor w -relief ridge
    grid $owms.title0$cnt2 -row 0 -column $cnt2  -sticky news

    set cnt1 1

    foreach item {blu red} {
      set cnt2 1
      ComboBox $owms.$cnt1$cnt2 -textvariable wms($name,2w,$item) -width 8 -justify right\
               -values $wms($name,$wms($name,type),lamda) -command "Valid2 $name" -modifycmd "Valid2 $name"
      grid $owms.$cnt1$cnt2 -row $cnt1 -column $cnt2  -sticky nw
      incr cnt1
    }
  }

### "Коэффициенты"

  set wmsn [frame .prop.nb.fr$ins]
  grid $wmsn -row 0 -column 0 -sticky nw

  $tnb tab configure $ins -window $wmsn -anchor nw
  incr ins

  set rw 0
  set cl 0
  foreach name $wms(zond) {
    set swms [labelframe $wmsn.fr${name} -text "SWMS_$name"]
    grid $swms -row $rw -column $cl -sticky news
    incr cl
    button $swms.bt1 -text "Коэффициенты" -command "EditCoefSWMS $name"
    grid  $swms.bt1 -row 0 -column 0  -sticky news
  }

### "Кнопки"

  set bt [frame .prop.frbt]
  grid $bt -row 1 -column 0 -sticky nw
    set clm 0
    button $bt.save -text "OK" -width 10 -command {

      SaveProp
      ReadIni
      foreach name $wms(zond) {

        catch {SaveChartPos $name}
        set wms($name,active) 0
        set wms($name,active) 1
        AddMZ $name
      }
      destroy .prop
    }
    grid $bt.save -row 0 -column $clm -padx 1 -pady 2
    incr clm

    button $bt.save2 -text "Применить" -width 10 -command Properties
    grid $bt.save2 -row 0 -column $clm -padx 1 -pady 2
    incr clm
    button $bt.savelog -text "Log" -width 10 -command SavePropLog
    grid $bt.savelog -row 0 -column $clm -padx 1 -pady 2
    incr clm
    button $bt.cnsl -text "Отмена" -width 10 -command "ReadIni; destroy .prop"
    grid $bt.cnsl -row 0 -column $clm -padx 1 -pady 2
    incr clm
}

proc Valid1 {name} {
global wms
  set list1 {}

  foreach nm $wms(zond) {

    lappend list1 $wms($nm,adr,adam)
  }
  
  foreach nm $wms(zond) {
    if {$wms($name,adr,adam)==$wms($nm,adr,adam) && $name!=$nm && $wms($name,adr,moxa)==$wms($nm,adr,moxa) } {
      foreach n {1 2} {
        if {[lsearch -all $list1 $n]<0} {

          set wms($nm,adr,adam) $n
        }
      }
    }
  }
}

proc Valid2 {name} {
global wms

  set list1 $wms($name,$wms($name,type),lamda)
  
  set a [lsearch $list1 $wms($name,2w,red)]
  set b [lsearch $list1 $wms($name,2w,blu)]
  
  if {$a>$b} {
  
    set wms($name,2w,red) [lindex $list1 $b]
    set wms($name,2w,blu) [lindex $list1 $a]

  } elseif {$a==$b} {
  
    if {$a==[expr {[llength $list1]-1}]} {

      set wms($name,2w,red) [lindex $list1 end-1]
      set wms($name,2w,blu) [lindex $list1 end]
    } else {
    
      set wms($name,2w,red) [lindex $list1 $a]
      set wms($name,2w,blu) [lindex $list1 [expr {$b+1}]]
    }
  }
}

proc ChooseDir {w name} {
global wms
  set dir [tk_chooseDirectory -parent . -initialdir $w -title "Выбор папки"]
  if {[llength $dir]} {set wms($name) $dir}
}

proc Clocks {} {
global wms
## Chasy
  set wms(clck) [clock format [clock seconds] -format "%H:%M:%S"]
  after 1000 Clocks
}

proc Data {} {
global wms meas
## Data
  set wms(dt) [clock format [clock seconds] -format "%d.%m.%Y"]
}

proc FormatXTicks {w value} {
  set label [format "%4.0f" $value]
  return $label
}

proc FindMeasDate {} {
global wms testmn

## Поиск всех тестовых замеров на текущий день и установка следующего имени замера

  set part "[clock format [clock seconds] -format "%y%m%d"]0"
  set g [glob -nocomplain -directory "$wms(DATAPATH)/$wms(dae)" -type d "${part}*"]
  set old 0

  if {[llength $g]} {

    foreach item $g {
      set part2 [lsearch -exact $wms(lst) [string range $item end end]]

      if {$old<=$part2} {set old $part2}
    }

    set testmn "${part}[lindex $wms(lst) [expr {$old+1}]]"
  } else {

    set testmn "${part}0"
  }
  lappend wms(mnlist) "$testmn"
  .fr1.com.mnlf.cb configure -values $testmn
  set wms(mn) $testmn
}

proc ClearChart {} {
global wms
  foreach name $wms(zond) {
    if {$wms($name,active)} {
      catch {global x${name}I x${name}IIo}
      x${name}I   set {}
      x${name}IIo set {}
      foreach l1 {300 460 520 630} {
        catch {global y${name}$l1 y${name}IIo$l1}
        y${name}${l1}    set {}
        y${name}IIo${l1} set {}
      }
    }
  }
}

proc SaveChartPos {name} {
global wms

  set f [open "./Data/Config/[info hostname]_${name}_chrt.cfg" "w"]
  set w .graph${name}
  set g [wm geometry $w]
  puts $f "$w $g"

  if {$wms($name,type)=="swms"} {

    puts $f "next"

    for {set i 0} {$i<3} {incr i} {

      set id [.graph$name.nb id $i]
      set w ".graph$name.nb.toplevel-$id"

      if {[winfo exists $w]} {

        puts $f ".graph$name.nb $i [wm geometry $w]"
      }
    }
  }
  close $f
}

proc ReadChartPos {name} {
global wms

  if {![catch {set of [open "./Data/Config/[info hostname]_${name}_chrt.cfg" "r"]}]} {

    set data [read $of]
    close $of

    set lines [split $data \n]

    set i 0
    set tb 0
    foreach str $lines {
      if {[llength $str]} {
        if {$str=="next"} {
          set tb 1
        } else {
          if {!$tb} {
            set w [lindex $str 0]
            set g [lindex $str 1]
            set gspl [split $g x+]
            set wdth [lindex $gspl 0]
            set hght [lindex $gspl 1]
            set x [lindex $gspl 2]
            set y [lindex $gspl 3]
            wm geometry $w "=${wdth}x${hght}+$x+$y"
          } else {
            set w [lindex $str 0]
            set tbb [lindex $str 1]
            set g [lindex $str 2]
            set gspl [split $g x+]
            set wdth [lindex $gspl 0]
            set hght [lindex $gspl 1]
            set x [lindex $gspl 2]
            set y [lindex $gspl 3]
            catch {blt::CreateTearoff $w $tbb $x $y}
            update
            set w "$w.toplevel-tab$tbb"
            catch {wm geometry $w "${wdth}x${hght}+$x+$y"}
          }
        }
      }
    }
  }
}

proc AddChart {name} {
global wms meas

  if {$wms($name,active)} {
    catch {destroy .graph$name}
    switch $name {
      S01 "set cnt2 1"
      S02 "set cnt2 2"
    }

    toplevel .graph$name
    wm geometry .graph$name "=+[expr {($cnt2*600)-550}]+600"
    wm title .graph$name "Graph_$name"

    set tnb [blt::tabnotebook .graph$name.nb -takefocus 1 -samewidth no]
    pack $tnb -expand yes -fill both
    set tab 0
    foreach tb {IIo I Spec} {
      catch {$tnb delete $tab; destroy $tnb.c${name}}
      switch $tb {

        "Spec" {

         $tnb insert $tab -text "$tb" -selectbackground RoyalBlue2

          set c [canvas $tnb.c${name}$tb -width 570 -height 300 -bg grey -highlightbackground  grey]
          pack $c
          $tnb tab configure $tab -window $c -anchor nw -fill both

          graph $c.sc -width 560 -height 300 -plotpadx {0 0} -plotpady {0 0} -plotbackground grey\
                           -fg black -bg grey
          $c create window 10 10 -window $c.sc -anchor nw

            global x${name}$tb y${name}$tb

            vector create x${name}$tb y${name}$tb

            $c.sc xaxis configure -title "l,nm" -min 200000 -max 1000000 -color black

            $c.sc grid configure -hide no -dashes {2 2} -color black

            $c.sc yaxis configure -title "I" -min 0 -titlecolor red -color red -justify right -rotate 90

            $c.sc element create "I" -ydata y${name}$tb -xdata  x${name}$tb\
             -label "" -mapy y -fill red -outline red -color red -pixels 0  -linewidth 1
        }
        "I" {

         $tnb insert $tab -text "$tb" -selectbackground RoyalBlue2

          set c [canvas $tnb.c${name}$tb -width 570 -height 300 -bg grey -highlightbackground  grey]
          pack $c
          $tnb tab configure $tab -window $c -anchor nw -fill both

          stripchart $c.sc -width 480 -height 300 -plotpadx {0 0} -plotpady {0 0} -plotbackground grey\
                           -fg black -bg grey
          $c create window 90 10 -window $c.sc -anchor nw

            global x${name}$tb y${name}630 y${name}520 y${name}460  y${name}300

            vector create x${name}$tb y${name}630 y${name}520 y${name}460 y${name}300

            $c.sc xaxis configure -title "" -min 0 -max [expr {ceil([lindex [lsort -real $wms($name,tr)] end]/10.)*10}] -color black

            $c.sc grid configure -hide no -dashes {2 2} -color black

            $c.sc yaxis configure -title "I" -min 0 -titlecolor black -color black -justify right -rotate 90

            $c.sc element create "I(630)" -ydata y${name}630 -xdata  x${name}$tb\
             -label "" -mapy y -fill red -symbol diamond -outline red -color red -pixels 3  -linewidth 1
            $c.sc element create "I(520)" -ydata y${name}520 -xdata  x${name}$tb\
             -label "" -mapy y -fill green -symbol diamond -outline green -color green -pixels 3  -linewidth 1
            $c.sc element create "I(460)" -ydata y${name}460 -xdata  x${name}$tb\
             -label "" -mapy y -fill blue -symbol diamond -outline blue -color blue -pixels 3  -linewidth 1
            $c.sc element create "I(300)" -ydata y${name}300 -xdata  x${name}$tb\
             -label "" -mapy y -fill violet -symbol diamond -outline violet -color violet -pixels 3  -linewidth 1

            frame $c.fr -width 80 -height 300 -bg grey
            $c create window 0 10 -window $c.fr -anchor nw
            set cnt 0
            foreach color {630 520 460 300} clr {red green blue violet} {

              label $c.fr.$color -text "I_$color" -fg $clr -bg grey -anchor nw -font -*-helvetica-bold-r-*-15-*-*-*-*-*-*-koi8-r
              grid  $c.fr.$color -row $cnt -column 0 -sticky news
              label $c.fr.var$color -textvar wms($name,I,$color) -fg $clr -bg grey -anchor nw -font -*-helvetica-bold-r-*-15-*-*-*-*-*-*-koi8-r
              grid  $c.fr.var$color -row $cnt -column 1 -sticky news
              incr cnt
            }
            label $c.fr.tr -text "tr" -fg brown -bg grey -anchor nw -font -*-helvetica-bold-r-*-15-*-*-*-*-*-*-koi8-r
            grid  $c.fr.tr -row $cnt -column 0 -sticky news
            label $c.fr.vartr -textvar wms($name,tr2) -fg brown -bg grey -anchor nw -font -*-helvetica-bold-r-*-15-*-*-*-*-*-*-koi8-r
            grid  $c.fr.vartr -row $cnt -column 1 -sticky news
            incr cnt
            label $c.fr.temp -text "T" -fg white -bg grey -anchor nw -font -*-helvetica-bold-r-*-15-*-*-*-*-*-*-koi8-r
            grid  $c.fr.temp -row $cnt -column 0 -sticky news
            label $c.fr.vartemp -textvar wms($name,t) -fg white -bg grey -anchor nw -font -*-helvetica-bold-r-*-15-*-*-*-*-*-*-koi8-r
            grid  $c.fr.vartemp -row $cnt -column 1 -sticky news
            incr cnt
        }
        "IIo" {

         $tnb insert $tab -text "$tb" -selectbackground RoyalBlue2

          set c [canvas $tnb.c${name}$tb -width 570 -height 300 -bg grey -highlightbackground  grey]
          pack $c
          $tnb tab configure $tab -window $c -anchor nw -fill both

          stripchart $c.sc -width 480 -height 300 -plotpadx {0 0} -plotpady {0 0} -plotbackground grey\
                           -fg black -bg grey
          $c create window 90 10 -window $c.sc -anchor nw

            global x${name}$tb y${name}IIo630 y${name}IIo520 y${name}IIo460 y${name}IIo300

            vector create x${name}$tb y${name}IIo630 y${name}IIo520 y${name}IIo460 y${name}IIo300

            $c.sc xaxis configure -title "" -min 0 -max [expr {ceil([lindex [lsort -real $wms($name,tr)] end]/10.)*10}] -color black

            $c.sc grid configure -hide no -dashes {2 2} -color black

#            $c.sc yaxis configure -title "I/Io" -min 0 -titlecolor black -color black -justify right -rotate 90
            $c.sc yaxis configure -title "I/Io" -titlecolor black -color black -justify right -rotate 90

            $c.sc element create "IIo(630)" -ydata y${name}IIo630 -xdata  x${name}$tb\
             -label "" -mapy y -fill red -symbol diamond -outline red -color red -pixels 3  -linewidth 1
            $c.sc element create "IIo(520)" -ydata y${name}IIo520 -xdata  x${name}$tb\
             -label "" -mapy y -fill green -symbol diamond -outline green -color green -pixels 3  -linewidth 1
            $c.sc element create "IIo(460)" -ydata y${name}IIo460 -xdata  x${name}$tb\
             -label "" -mapy y -fill blue -symbol diamond -outline blue -color blue -pixels 3  -linewidth 1
            $c.sc element create "IIo(300)" -ydata y${name}IIo300 -xdata  x${name}$tb\
             -label "" -mapy y -fill violet -symbol diamond -outline violet -color violet -pixels 3  -linewidth 1

            frame $c.fr -width 80 -height 300 -bg grey
            $c create window 0 10 -window $c.fr -anchor nw
            set cnt 0
            foreach color {630 520 460 300} clr {red green blue violet} {

              label $c.fr.$color -text "I/Io_$color" -fg $clr -bg grey -anchor nw -font -*-helvetica-bold-r-*-15-*-*-*-*-*-*-koi8-r
              grid  $c.fr.$color -row $cnt -column 0 -sticky news
              label $c.fr.var$color -textvar wms($name,IIo,$color) -fg $clr -bg grey -anchor nw -font -*-helvetica-bold-r-*-15-*-*-*-*-*-*-koi8-r
              grid  $c.fr.var$color -row $cnt -column 1 -sticky news
              incr cnt
            }
            label $c.fr.tr -text "tr" -fg brown -bg grey -anchor nw -font -*-helvetica-bold-r-*-15-*-*-*-*-*-*-koi8-r
            grid  $c.fr.tr -row $cnt -column 0 -sticky news
            label $c.fr.vartr -textvar wms($name,tr2) -fg brown -bg grey -anchor nw -font -*-helvetica-bold-r-*-15-*-*-*-*-*-*-koi8-r
            grid  $c.fr.vartr -row $cnt -column 1 -sticky news
            incr cnt
            label $c.fr.temp -text "T" -fg white -bg grey -anchor nw -font -*-helvetica-bold-r-*-15-*-*-*-*-*-*-koi8-r
            grid  $c.fr.temp -row $cnt -column 0 -sticky news
            label $c.fr.vartemp -textvar wms($name,t) -fg white -bg grey -anchor nw -font -*-helvetica-bold-r-*-15-*-*-*-*-*-*-koi8-r
            grid  $c.fr.vartemp -row $cnt -column 1 -sticky news
            incr cnt
        }
      }
      incr tab
    }
    catch {ReadChartPos $name}
  } else {
  
    catch {SaveChartPos $name}
    catch {destroy .graph$name}
  }
}

proc ConfPause2 {pause} {
global wms
  if {$pause} {
    set txt "Продолжить"
    set cmd "StartMeas"
    set state active
  } else {
    set txt "Пауза"
    set cmd "set dp(pause) 1;.fr1.com.startlf.bt1 configure -state disabled"
    set state disabled
  }
## Perekonf-tsija knopki Pauza v knopku Prodolzhit'
  .fr1.com.startlf.bt1 configure -text $txt -command "$cmd" -state active
  set i 1
  foreach name $wms(zond) {
    .fr1.zond.title10$i configure -state $state
    incr i
  }
  update
}

proc FormInfo {} {
global wms

  set str ""
  foreach item {active temp zndjntctr calculate} inf {Active Temp Joint_cntr Post_calc} {
    if {$wms($item)} {
      set str "${str}$inf; "
    }
  }
  foreach name $wms(zond) {
    foreach nitem {Iсв1 Iсв2} item {Io1 Io2} {
      if {$wms($name,$item)} {
        set str "${str}${name}_${nitem}; "
      }
    }
    set str "${str}${name}_$wms($name,meth); "
  }
  set wms(Info) $str
}

proc ExitPr {} {
global rs wms

  catch exitsm
  foreach name $wms(zond) {
    catch {SaveChartPos $name}
  }
  set f [open "Data/Config/[info hostname].ini" "w"]
  set w .
  set g [wm geometry $w]
  puts $f "$w $g"
  close $f
  exit
}