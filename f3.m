function f=f3(x)
load data2 qq1 qq2 keseip pp1 pp2 b1 b2 uu1
f=-(x-b2).*(qq1+(keseip*qq1*qq2*(uu1-pp1))/(qq1+qq2)-(keseip*qq1*qq2*(x-pp2))./(qq1+qq2));