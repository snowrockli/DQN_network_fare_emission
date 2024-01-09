%=======================���ǿ��ѧϰ�����������ۣ����Ǽ��ţ�================
clc
clear
close all
OD=xlsread('OD.xlsx','demand');%OD�������
TT=xlsread('OD.xlsx','travel_time');%վ�������ʱ�����
T_DQN=400;%ǿ��ѧϰ��������
t_learn=100;%�Ӿ���طż�����ѡȡ������ʱ��
gama=0.7;%ǿ��ѧϰ��
epsilon(1)=0.3;%��������
basic_num=50;%�Ӿ���طż�����ѡȡ����������
%A=[-3;-1;0;1;3];%����
A_s=[1,0,0,0
     0,1,0,0
     0,0,1,0
     0,0,0,1
     0,0,0,0
     0,0,0,-1
     0,0,-1,0
     0,-1,0,0
     -1,0,0,0];
max_As=size(A_s,1);%��������
D=[];%����طż���
D_train=[];%Qֵѵ������
%=============��ʼ��Ʊ�������״̬================
p(1,1)=0.4;
p(2,1)=0.4;
p(3,1)=0.4;
p(4,1)=0.4;
%p_a(1)=5;
min_p=0;%�۸�����
max_p=1.0;%�۸�����
eita=0.01;%�۸������
%====================��ʼ��������============
num_sample=T_DQN;
S_A=rand(num_sample,5);%����������
Q=rand(num_sample,1);%���������
net=newff(S_A',Q',11,{'logsig','purelin','traingd'});
net.trainParam.showWindow = 0;%�Ƿ�չʾ����
%=============����ѵ��=====================
for t=1:T_DQN
    %===========����״̬�����Qֵ================
    STATE=[p(1,t),p(2,t),p(3,t),p(4,t)];%״̬
    for a_n=1:length(A_s)
        x_S_A(:,a_n)=[STATE,a_n]';
        y_Q(a_n)=sim(net,x_S_A(:,a_n)); %��ͬ������Qֵ
    end
    %===========ѡ����============
    if rand<epsilon(t)
        i_star=randi([1,length(A_s)],1,1);%���ѡ��
        i_select=i_star(1);
    else
        i_star=find(y_Q==max(y_Q));%ѡQֵ����
        i_select=i_star(randi([1,length(i_star)],1,1));%ѡ�����Ķ������
    end
    epsilon(t+1)=epsilon(t)-0.001;
    %===============ִ��ѡ��Ķ������õ��µ�״̬==============
%     p_a(t+1)=p_a(t)+A(i_select);
%     if p_a(t+1)>max_As||p_a(t+1)<1
%         p_a(t+1)=p_a(t);
%     end
    p(1,t+1)=p(1,t)*(1+A_s(i_select,1)*eita);
    p(2,t+1)=p(2,t)*(1+A_s(i_select,2)*eita);
    p(3,t+1)=p(3,t)*(1+A_s(i_select,3)*eita);
    p(4,t+1)=p(4,t)*(1+A_s(i_select,4)*eita);
    %===============���¾���طż���========================
    %REWARD=f_reward_logit(p,t,OD,TT);
    REWARD=f_reward_neural(p,t,OD,TT);
    for i_p=1:4
        if p(i_p,t+1)<=min_p||p(i_p,t+1)>=max_p
            p(i_p,t+1)=p(i_p,t);
        end
    end
    NEW_STATE=[p(1,t+1),p(2,t+1),p(3,t+1),p(4,t+1)];
    D(t,:)=[STATE,i_select,REWARD,NEW_STATE];
    %===============�Ӿ���طż�����ѡȡһЩ����====================
    D_train_temp=[];
    if t>=t_learn%�жϼ������������Ƿ��㹻
        c=randperm(numel(1:t));%���´���˳��
        m=basic_num;%ѡ��m������
        for i=1:m
            D_train_temp(i,1:size(STATE,2)+1)=D(c(i),1:size(STATE,2)+1);
            STATE_next=D(c(i),size(STATE,2)+3:end);%��һ��״̬
            for a_n=1:length(A_s)
                x_next_S_A(:,a_n)=[STATE_next,a_n]';
                y_next_Q(a_n)=sim(net,x_next_S_A(:,a_n)); %��ͬ������Qֵ
            end
            max_Q=max(y_next_Q);
            D_train_temp(i,size(STATE,2)+2)=D(c(i),size(STATE,2)+2)+gama*max_Q;%����Qֵ
        end
        %===============����Qֵѵ����=================
        [D_train_num,~]=size(D_train);
        if isempty(D_train)==1
            D_train=D_train_temp;
        else
            for i=1:m
                for j=1:D_train_num
                    if isequal(D_train_temp(i,1:size(STATE,2)+1),D_train(j,1:size(STATE,2)+1))==1
                        D_train(j,size(STATE,2)+2)=D_train_temp(i,size(STATE,2)+2);%��ѵ���������״̬һ���ģ�����Qֵ
                    end
                end
            end
            for i=1:m
                if ismember(D_train_temp(i,1:size(STATE,2)+1),D_train(:,1:size(STATE,2)+1),'rows')==0
                    [D_train_num,~]=size(D_train);
                    D_train(D_train_num+1,:)=D_train_temp(i,:);%�µ�״̬�Ͷ�����ֱ�����
                end
            end
        end
        %D_train=unique(D_train,'rows');
        net = train(net,D_train(:,1:size(STATE,2)+1)',D_train(:,size(STATE,2)+2)');
        net.trainParam.goal =1e-5;% 1e-5;
        net.trainParam.epochs = 300;
        net.trainParam.lr = 0.05;
        net.trainParam.showWindow = 0;%�Ƿ�չʾ����
        
    end
    
end




 
 
 
