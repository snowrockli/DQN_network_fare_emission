function f=f_reward_logit(p,t,OD,TT)
t_e=1;
t_T=6;
theita=0.7;%效用感知系数
kesei=0.01;%非交互效用系数
kesei_p=0.2;%价格敏感度
theita_l_so=1.5;%社会交互水平
capacity=100;%拥挤阈值
speed=20;%车速km/小时
%==============线路=============
route(1,:)=[12,11,10,8,6,4,5,2];
route(2,:)=[14,10,13,11,12,4,2,1];
route(3,:)=[9,15,7,10,8,6,0,0];
route(4,:)=[1,2,3,6,8,15,7,10];
[num_route,~]=size(route);
%==============单位里程票价=============
p_route(1)=p(1,t+1);
p_route(2)=p(2,t+1);
p_route(3)=p(3,t+1);
p_route(4)=p(4,t+1);
p_car_0=2;%网约车单位里程费用
p_car=bl_logit(p_route,p_car_0);%求解网约车费用
%============发车频率=========
f_route(1)=5;
f_route(2)=5;
f_route(3)=5;
f_route(4)=5;
%===========站点数量==========
[num_station,~]=size(OD);
%==============初始化===================
%========判断站点间是否直达=============
for i=1:num_station
    for j=1:num_station
        for k=1:num_route
            if ismember(i,route(k,:))==1&&ismember(j,route(k,:))==1
                transf(i,j)=0;%一条线上不用换乘
                break;
            else
                transf(i,j)=-1;%否则站点不直达
            end
        end
    end
end
for i=1:num_station
    for j=1:num_station
        cell{i,j}.route_num=0;%线路数量
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
        %=========确定每个OD间线路数量与名称============
        for k=1:num_route
            if ismember(i,route(k,:))&&ismember(j,route(k,:))&&(i~=j)
                cell{i,j}.route_num=cell{i,j}.route_num+1;
                cell{i,j}.route=[cell{i,j}.route,k];%添加线路名称
                cell{i,j}.i_locate(cell{i,j}.route_num,1)=find(ismember(route(k,:),i));%定位起点在线路中的位置
                cell{i,j}.j_locate(cell{i,j}.route_num,1)=find(ismember(route(k,:),j));%定位终点在线路中的位置
                if cell{i,j}.i_locate(cell{i,j}.route_num,1)<cell{i,j}.j_locate(cell{i,j}.route_num,1)%方向
                    cell{i,j}.direction(cell{i,j}.route_num,1)=1;%上行
                else
                    cell{i,j}.direction(cell{i,j}.route_num,1)=-1;%下行
                end
            end
        end
        %==============计算每个OD间的实际路径==============
        cell{i,j}.real_route=zeros(cell{i,j}.route_num,num_station);
        for k=1:cell{i,j}.route_num
            if cell{i,j}.direction(k)==1%上行实际的路径
                cell{i,j}.route_length(k)=size(route(cell{i,j}.route(k),cell{i,j}.i_locate(k,1):cell{i,j}.j_locate(k,1)),2);
                cell{i,j}.real_route(k,1:cell{i,j}.route_length(k))=route(cell{i,j}.route(k),cell{i,j}.i_locate(k,1):cell{i,j}.j_locate(k,1));
            elseif cell{i,j}.direction(k)==-1%下行实际的路径
                cell{i,j}.route_length(k)=size(route(cell{i,j}.route(k),cell{i,j}.j_locate(k,1):cell{i,j}.i_locate(k,1)),2);
                cell{i,j}.real_route(k,1:cell{i,j}.route_length(k))=route(cell{i,j}.route(k),cell{i,j}.j_locate(k,1):cell{i,j}.i_locate(k,1));
            end
        end
    end
end
%==============开始演化=================
while t_e<=t_T
    for i=1:num_station
        for j=1:num_station
            if transf(i,j)==0%可以直达
                %===========公交行程时间、等待时间、票价=================
                for k=1:cell{i,j}.route_num
                    cell{i,j}.bus_travel_time(k)=0;
                    non_zero=cell{i,j}.real_route(k,(find(cell{i,j}.real_route(k,:)~=0)));%提取实际线路
                    for kk=1:length(non_zero)-1
                        cell{i,j}.bus_travel_time(k)=cell{i,j}.bus_travel_time(k)+TT(non_zero(kk),non_zero(kk+1));%线路行程时间
                    end
                    cell{i,j}.bus_fare(k)=p_route(cell{i,j}.route(k))*cell{i,j}.bus_travel_time(k)*speed/60;%公交票价
                    cell{i,j}.bus_wait_time(k)=1/f_route(cell{i,j}.route(k));%公交等待时间
                end
                %===========网约车行程时间、等待时间、票价=================
                cell{i,j}.car_travel_time=min(cell{i,j}.bus_travel_time);%行程时间
                cell{i,j}.car_fare=p_car*cell{i,j}.car_travel_time*speed/60;%网约车费
                cell{i,j}.car_wait_time=0;%网约车等待时间
                %===========计算广义出行费用=====================
                if t_e==1&&i~=j
                    %=========网约车广义费用=================
                    cell{i,j}.car_fee=kesei*cell{i,j}.car_travel_time+kesei*cell{i,j}.car_wait_time+kesei_p*cell{i,j}.car_fare;
                    cell{i,j}.car_fee_b=cell{i,j}.car_fee;
                    %========公交车广义费用==================
                    for k=1:cell{i,j}.route_num
                        cell{i,j}.bus_fee(k)=kesei*cell{i,j}.bus_travel_time(k)+kesei*cell{i,j}.bus_wait_time(k)+kesei_p*cell{i,j}.bus_fare(k);
                        cell{i,j}.bus_fee_b(k)=cell{i,j}.bus_fee(k);
                    end
                elseif t_e>1&&i~=j
                    %=========网约车广义费用=================
                    cell{i,j}.car_fee=kesei*cell{i,j}.car_travel_time+kesei*cell{i,j}.car_wait_time+kesei_p*cell{i,j}.car_fare+kesei*cell{i,j}.car_q/(f_route(k)*capacity)+theita_l_so*sum(cell{i,j}.bus_q(:))/mean(OD(:));
                    cell{i,j}.car_fee_b=cell{i,j}.car_fee-theita_l_so*sum(cell{i,j}.bus_q(:))/mean(OD(:));%排除社会交互作用
                    %========公交车广义费用==================
                    for k=1:cell{i,j}.route_num
                        cell{i,j}.bus_fee(k)=kesei*cell{i,j}.bus_travel_time(k)+kesei*cell{i,j}.bus_wait_time(k)+kesei_p*cell{i,j}.bus_fare(k)+kesei*cell{i,j}.bus_crowd(k)/(f_route(k)*capacity)+theita_l_so*cell{i,j}.car_q/mean(OD(:));
                        cell{i,j}.bus_fee_b(k)=cell{i,j}.bus_fee(k)-theita_l_so*cell{i,j}.car_q/mean(OD(:));%排除社会交互作用
                    end
                end
                %===============计算选择不同线路的人数=====================
                if i~=j
                    %========选择网约车出行人数=========
                    cell{i,j}.car_q=OD(i,j)*exp(-theita*cell{i,j}.car_fee)/(sum(exp(-theita*cell{i,j}.bus_fee(:)))+exp(-theita*cell{i,j}.car_fee));
                    car_q(i,j)=cell{i,j}.car_q;
                    %========选择公交出行人数===========
                    for k=1:cell{i,j}.route_num
                        cell{i,j}.bus_q(k)=OD(i,j)*exp(-theita*cell{i,j}.bus_fee(k))/(sum(exp(-theita*cell{i,j}.bus_fee(:)))+exp(-theita*cell{i,j}.car_fee));
                    end
                end
            else%如果站点间无法公交直达
                cell{i,j}.car_travel_time=TT(i,j);
                cell{i,j}.car_fare=p_car*cell{i,j}.car_travel_time*speed/60;
                cell{i,j}.car_q=OD(i,j);
                cell{i,j}.car_fee=kesei*cell{i,j}.car_fare+kesei*cell{i,j}.car_travel_time;
                car_q(i,j)=cell{i,j}.car_q;
            end
        end
    end
    car_qq(t_e)=mean(mean(car_q(:,:)));%检查收敛性
    if t_e==1
        q_var(t_e)=0;
    else
        q_var(t_e)=abs(car_qq(t_e)-car_qq(t_e-1))/car_qq(t_e-1);%检查收敛性
    end
    %=============计算每条线路的使用情况===========
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
    %===========计算每个路段的拥挤程度（上行）================
    for k=1:size(route,1)
        for ii=1:size(route,2)-1
            if route(k,ii)*route(k,ii+1)==0
                crowd(k,ii,1)=0;%上行
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
    %===========计算每个路段的拥挤程度（下行）================
    for k=1:size(route,1)
        for ii=size(route,2):-1:2
            if route(k,ii)*route(k,ii-1)==0
                crowd(k,ii-1,2)=0;%下行
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
    %==================计算每个OD间的拥挤度===================
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
% f(1)%目标函数1：票价收入最大化
% f(2)%目标函数2：排放最小化
e_bus=0.036;%新能源公交排放
e_car=0.51;%小汽车排放
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
                profit(i,j)=sum(bus_profit(:));%票价、停车费收入
                g_fee(i,j)=sum(bus_g_fee(:));%出行广义费用
                emission(i,j)=sum(bus_emission(:))+car_emission;%排放
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