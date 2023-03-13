<table>
<tr>
<th> Rule </th> <th> Parse tree </th> <th> Symbols </th> <th> Input </th> 
</tr>
<tr> <td> (5) </td>

<td>
<div class="mermaid">
graph
  J-->LB["{"]
  J-->NS 
  J-->RB["}"]
</div>
</td>          

<td>
 <u>{ </u> NS }
</td>

<td>
 <u>{ </u> ' k  1 ' : 1 , ' k 2 ' : [ ] }
</td>


</tr>

<tr>
<td>

</td>
<td>
<div class="mermaid">
graph
  J-->LB["{"]
  J-->NS 
  J-->RB["}"]
</div>
</td>

<td>
  NS }
</td>

<td>
 ' k  1 ' : 1 , ' k 2 ' : [ ] }
</td>

</tr>

<tr>
<td>
(8)
</td>

<td>
<div class="mermaid">
graph
  J-->LB["{"]
  J-->NS 
  J-->RB["}"]
  NS-->N
  NS-->,
  NS-->NS2["NS"]
</div>
</td>

<td>
N,NS }
</td>

<td>
 ' k  1 ' : 1 , ' k 2 ' : [ ] }
</td>
</tr>


<tr>
<td>
(10)
</td>

<td>
<div class="mermaid">
graph
  J-->LB["{"]
  J-->NS 
  J-->RB["}"]
  NS-->N
  NS-->,
  NS-->NS2["NS"]
  N-->LQ[']
  N-->s
  N-->RQ[']
  N-->:
  N-->J2[J]
</div>
</td>

<td>
<u>'</u> s':J, NS }
</td>

<td>
<u>'</u> k  1 ' : 1 , ' k 2 ' : [ ] }
</td>
</tr>



<tr>
<td>

</td>

<td>
<div class="mermaid">
graph
  J-->LB["{"]
  J-->NS 
  J-->RB["}"]
  NS-->N
  NS-->,
  NS-->NS2["NS"]
  N-->LQ[']
  N-->s
  N-->RQ[']
  N-->:
  N-->J2[J]
</div>
</td>

<td>
<u>s</u>':J, NS }
</td>

<td>
<u>k 1</u> ' : 1 , ' k 2 ' : [ ] }
</td>
</tr>


<tr>
<td>

</td>

<td>
<div class="mermaid">
graph
  J-->LB["{"]
  J-->NS 
  J-->RB["}"]
  NS-->N
  NS-->,
  NS-->NS2["NS"]
  N-->LQ[']
  N-->S1("s(k1)")
  N-->RQ[']
  N-->:
  N-->J2[J]
</div>
</td>

<td>
<u>'</u>:J, NS }
</td>

<td>
<u>'</u> : 1 , ' k 2 ' : [ ] }
</td>
</tr>


<tr>
<td>

</td>

<td>
<div class="mermaid">
graph
  J-->LB["{"]
  J-->NS 
  J-->RB["}"]
  NS-->N
  NS-->,
  NS-->NS2["NS"]
  N-->LQ[']
  N-->S1("s(k1)")
  N-->RQ[']
  N-->:
  N-->J2[J]
</div>
</td>

<td>
<u>:</u>J, NS }
</td>

<td>
<u>:</u> 1 , ' k 2 ' : [ ] }
</td>
</tr>


<tr>
<td>

</td>

<td>
<div class="mermaid">
graph
  J-->LB["{"]
  J-->NS 
  J-->RB["}"]
  NS-->N
  NS-->,
  NS-->NS2["NS"]
  N-->LQ[']
  N-->S1("s(k1)")
  N-->RQ[']
  N-->:
  N-->J2[J];
</div>
</td>

<td>
J, NS }
</td>

<td>
1 , ' k 2 ' : [ ] }
</td>
</tr>



<tr>
<td>
(1)
</td>

<td>
<div class="mermaid">
graph
  J-->LB["{"]
  J-->NS 
  J-->RB["}"]
  NS-->N
  NS-->,
  NS-->NS2["NS"]
  N-->LQ[']
  N-->S1("s(k1)")
  N-->RQ[']
  N-->:
  N-->J2[J]
  J2-->i;
</div>
</td>

<td>
<u>i</u>, NS }
</td>

<td>
<u>1</u> , ' k 2 ' : [ ] }
</td>
</tr>



<tr>
<td>

</td>

<td>
<div class="mermaid">
graph
  J-->LB["{"]
  J-->NS 
  J-->RB["}"]
  NS-->N
  NS-->,
  NS-->NS2["NS"]
  N-->LQ[']
  N-->S1("s(k1)")
  N-->RQ[']
  N-->:
  N-->J2[J]
  J2-->i["i(1)"];
</div>
</td>

<td>
<u>,<u> NS }
</td>

<td>
<u>,</u> ' k 2 ' : [ ] }
</td>
</tr>


<tr>
<td>

</td>

<td>
<div class="mermaid">
graph
  J-->LB["{"]
  J-->NS 
  J-->RB["}"]
  NS-->N
  NS-->,
  NS-->NS2["NS"]
  N-->LQ[']
  N-->S1("s(k1)")
  N-->RQ[']
  N-->:
  N-->J2[J]
  J2-->i["i(1)"];
</div>
</td>

<td>
NS }
</td>

<td>
' k 2 ' : [ ] }
</td>
</tr>


<tr>
<td>
(9)
</td>

<td>
<div class="mermaid">
graph
  J-->LB["{"]
  J-->NS 
  J-->RB["}"]
  NS-->N
  NS-->,
  NS-->NS2["NS"]
  N-->LQ[']
  N-->S1("s(k1)")
  N-->RQ[']
  N-->:
  N-->J2[J]
  J2-->i["i(1)"]
  NS2-->N2[N];
</div>
</td>

<td>
N }
</td>

<td>
' k 2 ' : [ ] }
</td>
</tr>


<tr>
<td>
(10)
</td>

<td>
<div class="mermaid">
graph
  J-->LB["{"]
  J-->NS 
  J-->RB["}"]
  NS-->N
  NS-->,
  NS-->NS2["NS"]
  N-->LQ[']
  N-->S1("s(k1)")
  N-->RQ[']
  N-->:
  N-->J2[J]
  J2-->i["i(1)"]
  NS2-->N2[N]
  N2-->LQ2[']
  N2-->S2[s]
  N2-->RQ2[']
  N2-->CL2[":"]
  N2-->J3[J];
</div>
</td>

<td>
<u>'</u>s':J }
</td>

<td>
<u>'</u> k 2 ' : [ ] }
</td>
</tr>



<tr>
<td>

</td>

<td>
<div class="mermaid">
graph
  J-->LB["{"]
  J-->NS 
  J-->RB["}"]
  NS-->N
  NS-->,
  NS-->NS2["NS"]
  N-->LQ[']
  N-->S1("s(k1)")
  N-->RQ[']
  N-->:
  N-->J2[J]
  J2-->i["i(1)"]
  NS2-->N2[N]
  N2-->LQ2[']
  N2-->S2[s]
  N2-->RQ2[']
  N2-->CL2[":"]
  N2-->J3[J];
</div>
</td>

<td>
<u>s</u>':J }
</td>

<td>
<u>k 2</u> ' : [ ] }
</td>
</tr>



<tr>
<td>

</td>

<td>
<div class="mermaid">
graph
  J-->LB["{"]
  J-->NS 
  J-->RB["}"]
  NS-->N
  NS-->,
  NS-->NS2["NS"]
  N-->LQ[']
  N-->S1("s(k1)")
  N-->RQ[']
  N-->:
  N-->J2[J]
  J2-->i["i(1)"]
  NS2-->N2[N]
  N2-->LQ2[']
  N2-->S2["s(k2)"]
  N2-->RQ2[']
  N2-->CL2[":"]
  N2-->J3[J];
</div>
</td>

<td>
<u>'</u>:J }
</td>

<td>
<u>'</u> : [ ] }
</td>
</tr>



<tr>
<td>

</td>

<td>
<div class="mermaid">
graph
  J-->LB["{"]
  J-->NS 
  J-->RB["}"]
  NS-->N
  NS-->,
  NS-->NS2["NS"]
  N-->LQ[']
  N-->S1("s(k1)")
  N-->RQ[']
  N-->:
  N-->J2[J]
  J2-->i["i(1)"]
  NS2-->N2[N]
  N2-->LQ2[']
  N2-->S2["s(k2)"]
  N2-->RQ2[']
  N2-->CL2[":"]
  N2-->J3[J];
</div>
</td>

<td>
<u>:</u>J }
</td>

<td>
<u>:</u> [ ] }
</td>
</tr>


<tr>
<td>

</td>

<td>
<div class="mermaid">
graph
  J-->LB["{"]
  J-->NS 
  J-->RB["}"]
  NS-->N
  NS-->,
  NS-->NS2["NS"]
  N-->LQ[']
  N-->S1("s(k1)")
  N-->RQ[']
  N-->:
  N-->J2[J]
  J2-->i["i(1)"]
  NS2-->N2[N]
  N2-->LQ2[']
  N2-->S2["s(k2)"]
  N2-->RQ2[']
  N2-->CL2[":"]
  N2-->J3[J];
</div>
</td>

<td>
J }
</td>

<td>
[ ] }
</td>
</tr>


<tr>
<td>
(3)
</td>

<td>
<div class="mermaid">
graph
  J-->LB["{"]
  J-->NS 
  J-->RB["}"]
  NS-->N
  NS-->,
  NS-->NS2["NS"]
  N-->LQ[']
  N-->S1("s(k1)")
  N-->RQ[']
  N-->:
  N-->J2[J]
  J2-->i["i(1)"]
  NS2-->N2[N]
  N2-->LQ2[']
  N2-->S2["s(k2)"]
  N2-->RQ2[']
  N2-->CL2[":"]
  N2-->J3[J]
  J3-->LSQ["["]
  J3-->RSQ["]"];
</div>
</td>

<td>
<u>[ ] }</u>
</td>

<td>
<u>[ ] }</u>
</td>
</tr>



<tr>
<td>

</td>

<td>
<div class="mermaid">
graph
  J-->LB["{"]
  J-->NS 
  J-->RB["}"]
  NS-->N
  NS-->,
  NS-->NS2["NS"]
  N-->LQ[']
  N-->S1("s(k1)")
  N-->RQ[']
  N-->:
  N-->J2[J]
  J2-->i["i(1)"]
  NS2-->N2[N]
  N2-->LQ2[']
  N2-->S2["s(k2)"]
  N2-->RQ2[']
  N2-->CL2[":"]
  N2-->J3[J]
  J3-->LSQ["["]
  J3-->RSQ["]"];
</div>
</td>

<td>

</td>

<td>

</td>
</tr>


</table>