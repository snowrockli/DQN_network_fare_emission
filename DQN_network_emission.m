%=======================深度强化学习公交线网定价（考虑减排）================
clc
clear
close all
OD=xlsread('OD.xlsx','demand');%OD需求矩阵
TT=xlsread('OD.xlsx','travel_time');%站点间运行时间矩阵
T_DQN=400;%强化学习迭代次数
t_learn=100;%从经验回放集合中选取样本的时间
gama=0.7;%强化学习率
epsilon(1)=0.3;%搜索策略
basic_num=50;%从经验回放集合中选取的样本数量
%A=[-3;-1;0;1;3];%动作
A_s=[1,0,0,0
     0,1,0,0
     0,0,1,0
     0,0,0,1
     0,0,0,0
     0,0,0,-1
     0,0,-1,0
     0,-1,0,0
     -1,0,0,0];
max_As=size(A_s,1);%最大动作编号
D=[];%经验回放集合
D_train=[];%Q值训练集合
%=============初始化票价与调节状态================
p(1,1)=0.4;
p(2,1)=0.4;
p(3,1)=0.4;
p(4,1)=0.4;
%p_a(1)=5;
min_p=0;%价格下限
max_p=1.0;%价格上限
eita=0.01;%价格调整量
%====================初始化神经网络============
num_sample=T_DQN;
S_A=rand(num_sample,5);%神经网络输入
Q=rand(num_sample,1);%神经网络输出
net=newff(S_A',Q',11,{'logsig','purelin','traingd'});
net.trainParam.showWindow = 0;%是否展示窗口
%=============迭代训练=====================
for t=1:T_DQN
    %===========输入状态，输出Q值================
    STATE=[p(1,t),p(2,t),p(3,t),p(4,t)];%状态
    for a_n=1:length(A_s)
        x_S_A(:,a_n)=[STATE,a_n]';
        y_Q(a_n)=sim(net,x_S_A(:,a_n)); %不同动作的Q值
    end
    %===========选择动作============
    if rand<epsilon(t)
        i_star=randi([1,length(A_s)],1,1);%随机选择
        i_select=i_star(1);
    else
        i_star=find(y_Q==max(y_Q));%选Q值最大的
        i_select=i_star(randi([1,length(i_star)],1,1));%选出来的动作编号
    end
    epsilon(t+1)=epsilon(t)-0.001;
    %===============执行选择的动作，得到新的状态==============
%     p_a(t+1)=p_a(t)+A(i_select);
%     if p_a(t+1)>max_As||p_a(t+1)<1
%         p_a(t+1)=p_a(t);
%     end
    p(1,t+1)=p(1,t)*(1+A_s(i_select,1)*eita);
    p(2,t+1)=p(2,t)*(1+A_s(i_select,2)*eita);
    p(3,t+1)=p(3,t)*(1+A_s(i_select,3)*eita);
    p(4,t+1)=p(4,t)*(1+A_s(i_select,4)*eita);
    %===============更新经验回放集合========================
    %REWARD=f_reward_logit(p,t,OD,TT);
    REWARD=f_reward_neural(p,t,OD,TT);
    for i_p=1:4
        if p(i_p,t+1)<=min_p||p(i_p,t+1)>=max_p
            p(i_p,t+1)=p(i_p,t);
        end
    end
    NEW_STATE=[p(1,t+1),p(2,t+1),p(3,t+1),p(4,t+1)];
    D(t,:)=[STATE,i_select,REWARD,NEW_STATE];
    %===============从经验回放集合中选取一些样本====================
    D_train_temp=[];
    if t>=t_learn%判断记忆池里的数据是否足够
        c=randperm(numel(1:t));%重新打乱顺序
        m=basic_num;%选出m个经验
        for i=1:m
            D_train_temp(i,1:size(STATE,2)+1)=D(c(i),1:size(STATE,2)+1);
            STATE_next=D(c(i),size(STATE,2)+3:end);%下一个状态
            for a_n=1:length(A_s)
                x_next_S_A(:,a_n)=[STATE_next,a_n]';
                y_next_Q(a_n)=sim(net,x_next_S_A(:,a_n)); %不同动作的Q值
            end
            max_Q=max(y_next_Q);
            D_train_temp(i,size(STATE,2)+2)=D(c(i),size(STATE,2)+2)+gama*max_Q;%更新Q值
        end
        %===============更新Q值训练集=================
        [D_train_num,~]=size(D_train);
        if isempty(D_train)==1
            D_train=D_train_temp;
        else
            for i=1:m
                for j=1:D_train_num
                    if isequal(D_train_temp(i,1:size(STATE,2)+1),D_train(j,1:size(STATE,2)+1))==1
                        D_train(j,size(STATE,2)+2)=D_train_temp(i,size(STATE,2)+2);%与训练集里既有状态一样的，更新Q值
                    end
                end
            end
            for i=1:m
                if ismember(D_train_temp(i,1:size(STATE,2)+1),D_train(:,1:size(STATE,2)+1),'rows')==0
                    [D_train_num,~]=size(D_train);
                    D_train(D_train_num+1,:)=D_train_temp(i,:);%新的状态和动作，直接添加
                end
            end
        end
        %D_train=unique(D_train,'rows');
        net = train(net,D_train(:,1:size(STATE,2)+1)',D_train(:,size(STATE,2)+2)');
        net.trainParam.goal =1e-5;% 1e-5;
        net.trainParam.epochs = 300;
        net.trainParam.lr = 0.05;
        net.trainParam.showWindow = 0;%是否展示窗口
        
    end
    
end




 
 
 
