function  p_car=bl_logit(p_route,p_car_0)
T=10;
t=1;
%========效用参数=========
keseip=2.5;%价格敏感系数
theita=2;%效用感知系数
%==========初始参数=========
min_p1=0;
max_p1=15;
p1(1)=mean(p_route);%公交初始价格
min_p2=0;
max_p2=7;
p2(1)=p_car_0;%共享网约车初始价格
t1=2;%公交行程时间
t2=1;%网约车行程时间
c1=2;%公交舒适度成本
c2=1;%网约车舒适度成本
b1=1;%公交单位成本
b2=5;%网约车单位成本
q1(1)=20;%公交初始人数
q2(1)=20;%网约车初始人数
while t<T
    g1(t)=keseip*p1(t)+t1+c1;
    g2(t)=keseip*p2(t)+t2+c2;
    q1(t+1)=(q1(1)+q2(1))*exp(-theita*g1(t))/(exp(-theita*(g1(t)))+exp(-theita*(g2(t))));%公交更新流量
    q2(t+1)=q1(1)+q2(1)-q1(t+1);%共享网约车更新流量
    qq1=q1(t+1);
    qq2=q2(t+1);
    %=================通过灵敏度分析预测旅客人数====================
    %=================更新价格======================
    pp1=p1(t);
    pp2=p2(t);
    for ii=1:10%松弛化方法求解Nash均衡
        save data1 qq1 qq2 keseip pp1 pp2 b1 b2 ii
        [x,fval1]=fminbnd('f1',min_p1,max_p1);
        u1(ii)=x;
        uu1=u1(ii);
        save data2 qq1 qq2 keseip pp1 pp2 b1 b2 uu1
        [x,fval2]=fminbnd('f3',min_p2,max_p2);
        u2(ii)=x;
        uu2=u2(ii);
        save data3 uu2
    end
    p1(t+1)=uu1;
    p2(t+1)=uu2;
    t=t+1;     
end
p_car=pp2;
end