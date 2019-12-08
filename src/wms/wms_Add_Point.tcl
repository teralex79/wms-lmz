## Добавление точек измерения

proc AddPoint {name} {

#  if {$wms($pfn,n)=="finish"} { return  }
  set pfn [string range $name 1 end]

global wms mtbl${pfn} row lststr

  catch {destroy .top$pfn}
  toplevel .top$pfn
  set v [format "%2.0f" $pfn]
  set x [expr {100+$v*10}]
  set y [expr {100+$v*5}]
  wm geometry .top$pfn "=+$x+$y"
  wm protocol .top$pfn WM_DELETE_WINDOW "destroy .top$pfn"
  
  set row($name) 0

#  set wms($name,n) 0

  foreach str $lststr($pfn,rwv) {

    set str [eval list $str]

    if {[llength $str]>1} {

      set mtbl${pfn}($row($name),0) [expr $row($name)+1]

      set mtbl${pfn}($row($name),1) [format "%4.1f" [lindex $str 0]]
      set mtbl${pfn}($row($name),2) [format "%4.1f" [lindex $str 1]]
      set mtbl${pfn}($row($name),3) [format "%4.3f" [lindex $str 2]]
      incr row($name)
#      incr wms($name,n)
    }
  }

  catch {destroy .top$pfn.pmenu}
  MKPopup $row($name) 5 $pfn

  set ht [expr {4.5*($row($name)+1)}]

  if {$ht>200} {set ht 203}

  set c [canvas .top$pfn.canv -bg grey -scrollregion {0c 0c 0c 80c} -height ${ht}m -width 8c -yscrollcommand ".top$pfn.sy set"]
  grid $c -row 0 -column 1 -padx 2 -sticky news

  set fr [frame $c.fr -bg grey]
  $c create window 0 0 -window $fr -anchor nw

  set mtable [table $fr.mtabl -titlerows [expr {$row($name) - $wms($name,points)+1}] -roworigin -1 -cols 5 -rows [expr {$row($name)+1}]\
   -variable mtbl${pfn} -bg white -browsecommand "catch {destroy .top$pfn.pmenu}; MKPopup %r %c $pfn"\
   -resizeborders none -validate 1 -vcmd {expr {[string match {*[0-9-.]} %S]||[expr {[string length %S]==0}]}}]
  grid $mtable -sticky news
  
  grid rowconfigure $fr 0 -minsize 3000
  
  scrollbar .top$pfn.sy -command [list $c yview]
  grid .top$pfn.sy -row 0 -column 3 -sticky news

  for {set i 0} {$i<$row($name)} {incr i} {

    set chb [checkbutton $mtable.chb$i -relief groove -variable wms($name,wet,[expr $i+1])]

    $mtable window config $i,4 -sticky news -window $chb

#    set a [expr {$i+1}]
#    set t${item}($i,1) $a
#    set t${item}($i,2) [lindex $param(${item},${a}) 1]
  }


  frame .top$pfn.frame2
  grid .top$pfn.frame2 -row 1 -column 0 -padx 2 -sticky nw

  button .top$pfn.frame2.msave -width 10 -text "Save" -command "FormRWVFile $pfn; destroy .top$pfn" -anchor c
  button .top$pfn.frame2.mcancel -width 10 -text "Cancel" -command "destroy .top$pfn" -anchor c
  pack .top$pfn.frame2.msave .top$pfn.frame2.mcancel -side left

  set coord "$row($name),0"

  $mtable tag configure Lock -state disable -bg grey -relief flat
  $mtable tag configure Font -font {TimesNewRoman 10 bold}

  $mtable tag configure active -bg white -fg black -relief sunken

  $mtable tag row Font -1

  $mtable tag col Lock 0 3 4

  set lst2 {№ Trav Ang Dens Wet}

  for {set i 0} {$i<5} {incr i} {

    set mtbl${pfn}(-1,$i) [lindex $lst2 $i]
  }

  bind $mtable <Double-Button-1> {
      %W delete active 0 end
  }

  bind $mtable <Button-3> "Bind $pfn %X %Y"
#  bind $mtable <KP_Enter> [bind $mtable <Return>]
  bind $mtable <Return>  "Bind2 $pfn %W; break"
}

proc MKPopup {r c pfn} {
global test row wms

	set name S$pfn

#  set test($pfn) "$r,$c"

  menu .top$pfn.pmenu -tearoff 0
  .top$pfn.pmenu add command -label "Add Row" -command "AddRow .top$pfn.canv.fr.mtabl $r $pfn"
  .top$pfn.pmenu add command -label "Add Row to End" -command "AddRow .top$pfn.canv.fr.mtabl $row($name) $pfn"
  .top$pfn.pmenu add command -label "Del Row" -command "DelRow .top$pfn.canv.fr.mtabl $r $pfn"
}

proc Bind {pfn xt yt} {

  set x [expr $xt+80]
  set y [expr $yt+20]

  tk_popup .top$pfn.pmenu $x $y 1
}

proc Bind2 {pfn W} {
global row test

  set r [$W index active row]
  set c [$W index active col]

#  set test($pfn) "2 $r,$c $row($name)"

  if {$c==2} {
    $W activate [incr r],1
  } else {
    $W selection clear all
    $W activate $r,[incr c]
  }
}

proc AddRow {mtable r pfn} {
global mtbl${pfn} row wms

  set mt "mtbl$pfn"

	set name S$pfn
	
  if {$r!=$row($name)} {

    $mtable insert rows $r -1
  } else {

    $mtable insert rows $r 1
  }
  for {set i 0} {$i<=$row($name)} {incr i} {

    set mtbl${pfn}($i,0) [expr $i+1]
  }
  if {$r>0} {

    set mtbl${pfn}($r,3) [set ${mt}([expr $r-1],3)]
  } else {
  
    set mtbl${pfn}($r,3) [set ${mt}(1,3)]
  }

  for {set i 0} {$i<=$row($name)} {incr i} {

    set ncb($name,$i) 0
  }

  for {set i 0} {$i<=$row($name)} {incr i} {

    catch {destroy $mtable.chb$i}

    if {$i<$row($name)} {

      if {$wms($name,wet,[expr $i+1])} {

        if {$i>=$r} {

          set wms($name,wet,[expr $i+1]) 0
          set ncb($name,[expr $i+1]) 1
        } else {

          set ncb($name,$i) 1
        }
      }
    }

    set wms($name,wet,[expr $i+1]) $ncb($name,$i)

    set chb [checkbutton $mtable.chb$i -relief groove -variable wms($name,wet,[expr $i+1])]

    $mtable window config $i,4 -sticky news -window $chb
  }

  incr row($name)
  .top$pfn.pmenu delete 1  
  .top$pfn.pmenu insert 1 command -label "Add Row to End" -command "AddRow .top$pfn.canv.fr.mtabl $row($name) $pfn"
}

proc DelRow {mtable r pfn} {
global mtbl${pfn} row

  set name S$pfn

  $mtable delete rows $r 1

  for {set i 0} {$i<$row($name)} {incr i} {

    set mtbl${pfn}($i,0) [expr $i+1]
  }

  incr row($name) -1
  .top$pfn.pmenu delete 1  
  .top$pfn.pmenu insert 1 command -label "Add Row to End" -command "AddRow .top$pfn.canv.fr.mtabl $row($name) $pfn"
}


