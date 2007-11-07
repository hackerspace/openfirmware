purpose: Get data and time from an NTP server using SNTP
\ See license at end of file

0 value ip-ih
: $call-ip  ip-ih $call-method  ;

d# 123 constant ntp-port#
h# 30 constant /sntp-request

: send-sntp-request  ( -- )
   /sntp-request " allocate-udp" $call-ip >r
   r@ /sntp-request erase
   3 3 lshift    \ SNTP version 3
   3 or          \ Client request
   r@ c!
   r@ /sntp-request  ntp-port# ntp-port# " send-udp-packet" $call-ip
   r> /sntp-request " free-udp" $call-ip
;
: receive-sntp-reply  ( -- true | d.timestamp false )
   ntp-port#  " receive-udp-packet" $call-ip  if   ( )  \ Timeout
      true exit
   then                           ( adr len src-port# )
   drop                           ( adr len )
   h# 30 <  if                    ( adr len )
      ." Bad NTP reply length" cr
      drop true exit
   then                           ( adr )
\   dup c@ h# c0 and  if           ( adr ) \ Check LI field
\      ." NTP server not synchronized" cr
\      drop true exit
\   then                           ( adr )
   dup h# 2c + be-l@              ( adr fraction )
   dup  0=  if                    ( adr fraction )
      ." NTP server not synchronized" cr
      2drop true exit
   then                           ( adr fraction )
   swap h# 28 + be-l@             ( fraction seconds )
   false                          ( d.timestamp false )
;
: try-sntp  ( hostname$ -- true | d.timestamp false )
   " ip" open-dev  to ip-ih
   ip-ih 0=  if
      ." Networking not available" cr
      true exit
   then

   d# 5,000 " set-timeout" $call-ip
   " $set-host" $call-ip
   send-sntp-request
   receive-sntp-reply
   ip-ih close-dev
;

defer ntp-servers
: default-ntp-servers  " 0.pool.ntp.org 1.pool.ntp.org 2.pool.ntp.org"  ;
' default-ntp-servers to ntp-servers

: ntp-timestamp  ( -- true | d.timestamp false )
   ntp-servers  begin  dup  while   ( rem$ )
      bl left-parse-string          ( rem$ server$ )
      ['] try-sntp  catch  if       ( rem$ x x )
         2drop                      ( rem$ )
      else                          ( rem$ [ true | d.timestamp false ] )
         0=  if                     ( rem$ d.timestamp )
            2nip false exit
         then                       ( rem$ )
      then                          ( rem$ )
   repeat                           ( rem$ )
   2drop  true
;

d# 2,208,988,800 constant unix-epoch

: ntp>time&date  ( d.timestamp -- s m h m d y )
   nip unix-epoch - unix-seconds>
;


\ LICENSE_BEGIN
\ Copyright (c) 2007 FirmWorks
\ 
\ Permission is hereby granted, free of charge, to any person obtaining
\ a copy of this software and associated documentation files (the
\ "Software"), to deal in the Software without restriction, including
\ without limitation the rights to use, copy, modify, merge, publish,
\ distribute, sublicense, and/or sell copies of the Software, and to
\ permit persons to whom the Software is furnished to do so, subject to
\ the following conditions:
\ 
\ The above copyright notice and this permission notice shall be
\ included in all copies or substantial portions of the Software.
\ 
\ THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
\ EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
\ MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
\ NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
\ LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
\ OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
\ WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
\
\ LICENSE_END
