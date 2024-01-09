function f=f_reward_logit(p,t,OD,TT)
t_e=1;
t_T=6;
theita=0.7;%Ч�ø�֪ϵ��
kesei=0.01;%�ǽ���Ч��ϵ��
kesei_p=0.2;%�۸����ж�
theita_l_so=1.5;%��ύ��ˮƽ
capacity=100;%ӵ����ֵ
speed=20;%����km/Сʱ
%==============��·=============
route(1,:)=[12,11,10,8,6,4,5,2];
route(2,:)=[14,10,13,11,12,4,2,1];
route(3,:)=[9,15,7,10,8,6,0,0];
route(4,:)=[1,2,3,6,8,15,7,10];
[num_route,~]=size(route);
%==============��λ���Ʊ��=============
p_route(1)=p(1,t+1);
p_route(2)=p(2,t+1);
p_route(3)=p(3,t+1);
p_route(4)=p(4,t+1);
p_car_0=2;%��Լ����λ��̷���
p_car=bl_logit(p_route,p_car_0);%�����Լ������
%============����Ƶ��=========
f_route(1)=5;
f_route(2)=5;
f_route(3)=5;
f_route(4)=5;
%===========վ������==========
[num_station,~]=size(OD);
%==============��ʼ��===================
%========�ж�վ����Ƿ�ֱ��=============
for i=1:num_station
    for j=1:num_station
        for k=1:num_route
            if ismember(i,route(k,:))==1&&ismember(j,route(k,:))==1
                transf(i,j)=0;%һ�����ϲ��û���
                break;
            else
                transf(i,j)=-1;%����վ�㲻ֱ��
            end
        end
    end
end
for i=1:num_station
    for j=1:num_station
        cell{i,j}.route_num=0;%��·����
        cell{i,j}.route=[];
        cell{i,j}.route_length=[];
        cell{i,j}.bus_travel_time=[];
        cell{i,j}.car_travel_time=[];
        cell{i,j}.bus_wait_time=[];
        cell{i,j}.car_wait_time=[];
        cell{i,j}.bus_fare=[];
        cell{i,j}.car_fare=[];
        cell{i,j}.real_route=[];
        cell{i,j}.direction=[];
        cell{i,j}.bus_fee=[];
        cell{i,j}.bus_fee_b=[];
        cell{i,j}.car_fee=[];
        cell{i,j}.car_fee_b=[];
        cell{i,j}.car_regret=[];
        cell{i,j}.bus_regret=[];
        %=========ȷ��ÿ��OD����·����������============
        for k=1:num_route
            if ismember(i,route(k,:))&&ismember(j,route(k,:))&&(i~=j)
                cell{i,j}.route_num=cell{i,j}.route_num+1;
                cell{i,j}.route=[cell{i,j}.route,k];%�����·����
                cell{i,j}.i_locate(cell{i,j}.route_num,1)=find(ismember(route(k,:),i));%��λ�������·�е�λ��
                cell{i,j}.j_locate(cell{i,j}.route_num,1)=find(ismember(route(k,:),j));%��λ�յ�����·�е�λ��
                if cell{i,j}.i_locate(cell{i,j}.route_num,1)<cell{i,j}.j_locate(cell{i,j}.route_num,1)%����
                    cell{i,j}.direction(cell{i,j}.route_num,1)=1;%����
                else
                    cell{i,j}.direction(cell{i,j}.route_num,1)=-1;%����
                end
            end
        end
        %==============����ÿ��OD���ʵ��·��==============
        cell{i,j}.real_route=zeros(cell{i,j}.route_num,num_station);
        for k=1:cell{i,j}.route_num
            if cell{i,j}.direction(k)==1%����ʵ�ʵ�·��
                cell{i,j}.route_length(k)=size(route(cell{i,j}.route(k),cell{i,j}.i_locate(k,1):cell{i,j}.j_locate(k,1)),2);
                cell{i,j}.real_route(k,1:cell{i,j}.route_length(k))=route(cell{i,j}.route(k),cell{i,j}.i_locate(k,1):cell{i,j}.j_locate(k,1));
            elseif cell{i,j}.direction(k)==-1%����ʵ�ʵ�·��
                cell{i,j}.route_length(k)=size(route(cell{i,j}.route(k),cell{i,j}.j_locate(k,1):cell{i,j}.i_locate(k,1)),2);
                cell{i,j}.real_route(k,1:cell{i,j}.route_length(k))=route(cell{i,j}.route(k),cell{i,j}.j_locate(k,1):cell{i,j}.i_locate(k,1));
            end
        end
    end
end
%==============��ʼ�ݻ�=================
while t_e<=t_T
    for i=1:num_station
        for j=1:num_station
            if transf(i,j)==0%����ֱ��
                %===========�����г�ʱ�䡢�ȴ�ʱ�䡢Ʊ��=================
                for k=1:cell{i,j}.route_num
                    cell{i,j}.bus_travel_time(k)=0;
                    non_zero=cell{i,j}.real_route(k,(find(cell{i,j}.real_route(k,:)~=0)));%��ȡʵ����·
                    for kk=1:length(non_zero)-1
                        cell{i,j}.bus_travel_time(k)=cell{i,j}.bus_travel_time(k)+TT(non_zero(kk),non_zero(kk+1));%��·�г�ʱ��
                    end
                    cell{i,j}.bus_fare(k)=p_route(cell{i,j}.route(k))*cell{i,j}.bus_travel_time(k)*speed/60;%����Ʊ��
                    cell{i,j}.bus_wait_time(k)=1/f_route(cell{i,j}.route(k));%�����ȴ�ʱ��
                end
                %===========��Լ���г�ʱ�䡢�ȴ�ʱ�䡢Ʊ��=================
                cell{i,j}.car_travel_time=min(cell{i,j}.bus_travel_time);%�г�ʱ��
                cell{i,j}.car_fare=p_car*cell{i,j}.car_travel_time*speed/60;%��Լ����
                cell{i,j}.car_wait_time=0;%��Լ���ȴ�ʱ��
                %===========���������з���=====================
                if t_e==1&&i~=j
                    %=========��Լ���������=================
                    cell{i,j}.car_fee=kesei*cell{i,j}.car_travel_time+kesei*cell{i,j}.car_wait_time+kesei_p*cell{i,j}.car_fare;
                    cell{i,j}.car_fee_b=cell{i,j}.car_fee;
                    %========�������������==================
                    for k=1:cell{i,j}.route_num
                        cell{i,j}.bus_fee(k)=kesei*cell{i,j}.bus_travel_time(k)+kesei*cell{i,j}.bus_wait_time(k)+kesei_p*cell{i,j}.bus_fare(k);
                        cell{i,j}.bus_fee_b(k)=cell{i,j}.bus_fee(k);
                    end
                elseif t_e>1&&i~=j
                    %=========��Լ���������=================
                    cell{i,j}.car_fee=kesei*cell{i,j}.car_travel_time+kesei*cell{i,j}.car_wait_time+kesei_p*cell{i,j}.car_fare+kesei*cell{i,j}.car_q/(f_route(k)*capacity)+theita_l_so*sum(cell{i,j}.bus_q(:))/mean(OD(:));
                    cell{i,j}.car_fee_b=cell{i,j}.car_fee-theita_l_so*sum(cell{i,j}.bus_q(:))/mean(OD(:));%�ų���ύ������
                    %========�������������==================
                    for k=1:cell{i,j}.route_num
                        cell{i,j}.bus_fee(k)=kesei*cell{i,j}.bus_travel_time(k)+kesei*cell{i,j}.bus_wait_time(k)+kesei_p*cell{i,j}.bus_fare(k)+kesei*cell{i,j}.bus_crowd(k)/(f_route(k)*capacity)+theita_l_so*cell{i,j}.car_q/mean(OD(:));
                        cell{i,j}.bus_fee_b(k)=cell{i,j}.bus_fee(k)-theita_l_so*cell{i,j}.car_q/mean(OD(:));%�ų���ύ������
                    end
                end
                %===============����ѡ��ͬ��·������=====================
                if i~=j
                    %========ѡ����Լ����������=========
                    cell{i,j}.car_q=OD(i,j)*exp(-theita*cell{i,j}.car_fee)/(sum(exp(-theita*cell{i,j}.bus_fee(:)))+exp(-theita*cell{i,j}.car_fee));
                    car_q(i,j)=cell{i,j}.car_q;
                    %========ѡ�񹫽���������===========
                    for k=1:cell{i,j}.route_num
                        cell{i,j}.bus_q(k)=OD(i,j)*exp(-theita*cell{i,j}.bus_fee(k))/(sum(exp(-theita*cell{i,j}.bus_fee(:)))+exp(-theita*cell{i,j}.car_fee));
                    end
                end
            else%���վ����޷�����ֱ��
                cell{i,j}.car_travel_time=TT(i,j);
                cell{i,j}.car_fare=p_car*cell{i,j}.car_travel_time*speed/60;
                cell{i,j}.car_q=OD(i,j);
                cell{i,j}.car_fee=kesei*cell{i,j}.car_fare+kesei*cell{i,j}.car_travel_time;
                car_q(i,j)=cell{i,j}.car_q;
            end
        end
    end
    car_qq(t_e)=mean(mean(car_q(:,:)));%���������
    if t_e==1
        q_var(t_e)=0;
    else
        q_var(t_e)=abs(car_qq(t_e)-car_qq(t_e-1))/car_qq(t_e-1);%���������
    end
    %=============����ÿ����·��ʹ�����===========
    q=zeros(num_station,num_station,num_route);
    for ii=1:num_station
        for jj=1:num_station
            for k=1:num_route
                if ii==jj
                    q(ii,jj,k)=0;
                else
                    if isempty(find(cell{ii,jj}.route==k))==1
                        q(ii,jj,k)=0;
                    else
                        q(ii,jj,k)=cell{ii,jj}.bus_q(find(cell{ii,jj}.route==k));
                    end
                end
            end
        end
    end
    %===========����ÿ��·�ε�ӵ���̶ȣ����У�================
    for k=1:size(route,1)
        for ii=1:size(route,2)-1
            if route(k,ii)*route(k,ii+1)==0
                crowd(k,ii,1)=0;%����
            else
                if ii==1
                    crowd(k,ii,1)=0;
                    for jj=ii+1:size(route,2)
                        if route(k,jj)~=0
                            crowd(k,ii,1)=crowd(k,ii,1)+q(route(k,ii),route(k,jj),k);
                        end
                    end
                else
                    q_hou=0;
                    q_qian=0;
                    for jj=ii+1:size(route,2)
                        if route(k,jj)~=0
                            q_hou=q_hou+q(route(k,ii),route(k,jj),k);
                        end
                    end
                    for jj=1:ii
                        if route(k,jj)~=0
                            q_qian=q_qian+q(route(k,jj),route(k,ii),k);
                        end
                    end
                    crowd(k,ii,1)=crowd(k,ii-1,1)+q_hou-q_qian;
                end
            end
        end
    end
    %===========����ÿ��·�ε�ӵ���̶ȣ����У�================
    for k=1:size(route,1)
        for ii=size(route,2):-1:2
            if route(k,ii)*route(k,ii-1)==0
                crowd(k,ii-1,2)=0;%����
            else
                if ii==size(route,2)
                    crowd(k,ii-1,2)=0;
                    for jj=ii-1:-1:1
                        if route(k,jj)~=0
                            crowd(k,ii-1,2)=crowd(k,ii-1,2)+q(route(k,ii),route(k,jj),k);
                        else
                            crowd(k,ii-1,2)=0;
                        end
                    end
                else
                    q_hou=0;
                    q_qian=0;
                    for jj=1:ii-1
                        if route(k,jj)~=0
                            q_hou=q_hou+q(route(k,ii),route(k,jj),k);
                        end
                    end
                    for jj=ii:size(route,2)
                        if route(k,jj)~=0
                            q_qian=q_qian+q(route(k,jj),route(k,ii),k);
                        end
                    end
                    crowd(k,ii-1,2)=crowd(k,ii,2)+q_hou-q_qian;
                end
            end
        end
    end
    %==================����ÿ��OD���ӵ����===================
    for i=1:num_station
        for j=1:num_station
            for k=1:cell{i,j}.route_num
                if cell{i,j}.direction(k)==1
                    cell{i,j}.bus_crowd(k)=sum(crowd(cell{i,j}.route(k),cell{i,j}.i_locate(k):cell{i,j}.j_locate(k)-1,1));
                elseif cell{i,j}.direction(k)==-1
                    cell{i,j}.bus_crowd(k)=sum(crowd(cell{i,j}.route(k),cell{i,j}.j_locate(k):cell{i,j}.i_locate(k)-1,2));
                end
            end
        end
    end
    t_e=t_e+1;
end
% f(1)%Ŀ�꺯��1��Ʊ���������
% f(2)%Ŀ�꺯��2���ŷ���С��
e_bus=0.036;%����Դ�����ŷ�
e_car=0.51;%С�����ŷ�
for i=1:num_station
    for j=1:num_station
        if i~=j
            bus_profit=[];
            bus_g_fee=[];
            bus_emission=[];
            if transf(i,j)==0
                for k=1:cell{i,j}.route_num
                    bus_profit(k)=cell{i,j}.bus_fare(k)*cell{i,j}.bus_q(k)-f_route(cell{i,j}.route(k))*5;
                    bus_g_fee(k)=cell{i,j}.bus_fee(k)*cell{i,j}.bus_q(k);
                    bus_emission(k)=cell{i,j}.bus_q(k)*e_bus*cell{i,j}.car_travel_time*speed/60;
                end
                car_profit=cell{i,j}.car_fare*cell{i,j}.car_q;
                car_g_fee=cell{i,j}.car_fee*cell{i,j}.car_q;
                car_emission=cell{i,j}.car_q*e_car*cell{i,j}.car_travel_time*speed/60;
                profit(i,j)=sum(bus_profit(:));%Ʊ�ۡ�ͣ��������
                g_fee(i,j)=sum(bus_g_fee(:));%���й������
                emission(i,j)=sum(bus_emission(:))+car_emission;%�ŷ�
            else
                car_emission=cell{i,j}.car_q*e_car*cell{i,j}.car_travel_time*speed/60;
                emission(i,j)=car_emission;
%                 car_profit=cell{i,j}.car_fare*cell{i,j}.car_q;
%                 car_g_fee=cell{i,j}.car_fee*cell{i,j}.car_q;
%                 profit(i,j)=car_profit;
%                 g_fee(i,j)=car_g_fee;
            end
        end
    end
end
f=0.1*(mean(mean(profit))-mean(mean(g_fee)));
%f=-mean(mean(emission));
end