function  p_car=bl_logit(p_route,p_car_0)
T=10;
t=1;
%========Ч�ò���=========
keseip=2.5;%�۸�����ϵ��
theita=2;%Ч�ø�֪ϵ��
%==========��ʼ����=========
min_p1=0;
max_p1=15;
p1(1)=mean(p_route);%������ʼ�۸�
min_p2=0;
max_p2=7;
p2(1)=p_car_0;%������Լ����ʼ�۸�
t1=2;%�����г�ʱ��
t2=1;%��Լ���г�ʱ��
c1=2;%�������ʶȳɱ�
c2=1;%��Լ�����ʶȳɱ�
b1=1;%������λ�ɱ�
b2=5;%��Լ����λ�ɱ�
q1(1)=20;%������ʼ����
q2(1)=20;%��Լ����ʼ����
while t<T
    g1(t)=keseip*p1(t)+t1+c1;
    g2(t)=keseip*p2(t)+t2+c2;
    q1(t+1)=(q1(1)+q2(1))*exp(-theita*g1(t))/(exp(-theita*(g1(t)))+exp(-theita*(g2(t))));%������������
    q2(t+1)=q1(1)+q2(1)-q1(t+1);%������Լ����������
    qq1=q1(t+1);
    qq2=q2(t+1);
    %=================ͨ�������ȷ���Ԥ���ÿ�����====================
    %=================���¼۸�======================
    pp1=p1(t);
    pp2=p2(t);
    for ii=1:10%�ɳڻ��������Nash����
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