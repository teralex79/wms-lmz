####### This gets called when a connection is made ##################
proc on_connect {newsock cAddr cPort}  {
  fconfigure $newsock -blocking 0
  fileevent  $newsock readable [list handleInput $newsock]
}
####### This gets called when there is data to read ##################

set tt(socket) {}

proc handleInput {f} {
global tt config idata

# Delete the handler if the input was exhausted.

  if {[eof $f]} {

    set a [lsearch $tt(socket) $f]
    set tt(socket) [lreplace $tt(socket) $a $a]
    if {[llength $tt(socket)]==0} {
      set tt(opensock) 0
    }
    fileevent $f readable {}
    close $f
    return
  }

#  set tt(socket) $f

# Read and handle the incoming information.
  set r [gets $f]
  set lr [eval list $r]

  if {[llength $lr]} {
    for {set i 0} {$i<6} {incr i} {

      set idata($i) [lindex $lr $i]
    }

    switch -exact $idata(0) {
    
      "Meas" {
#puts "Meas $f $idata(1)"
        set tt($f,$idata(1),cnt) 1
        set tt($f,$idata(1),n) $idata(2)
        set tt($f,$idata(1),rep) $idata(3)
        set tt($f,$idata(1),nmbcnt) $idata(4)
        set tt($f,$idata(1),meas) 1
      }
      "ConTT" {
#puts "Connect $f $idata(1)"
        foreach par $config(pars_name) {
          set tt($f,$par,meas) 0
        }

			  set tt(opensock) 1
        sendMes $f "Connect"
        lappend tt(socket) $f
      }
      "Exit" {

        exitProg
      }

      default {

        sendMes $f "Error - unknown command TT $idata(0)"
      }
    }
  }
}

proc sendMes {sock str} {
global tt
#puts "Send temp $sock $str"
#update
  set tf [clock format [clock seconds] -format %H:%M:%S]
  catch {puts $sock "$tf $str"}
  catch {flush $sock}
}
