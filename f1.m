function f=f1(x)
load data1 qq1 qq2 keseip pp1 pp2 b1 b2 ii
if ii==1
    f=-(x-b1).*(qq1-(keseip*qq1*qq2*(x-pp1))./(qq1+qq2));
else
    load data3 uu2
    f=-(x-b1).*(qq1-(keseip*qq1*qq2*(x-pp1))./(qq1+qq2)+(keseip*qq1*qq2*(uu2- pp2))/(qq1+qq2));
end