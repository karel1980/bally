camera {location<0,0,-3> look_at<0,0,0>}
light_source{<30,30,-20>  color rgb 1}  
light_source{<10,30,-200> color rgb 1} 
#include "netball.inc" 

object {NB_Netball("Moulded")
  rotate x*360*clock
} 

