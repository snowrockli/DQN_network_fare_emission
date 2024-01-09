function cell=multi_agent_neural(t,i,j,cell,OD,N_agent_length)
theita_l_so=0.7;
if i~=j
    input_num=cell{i,j}.route_num+1;%�������Ԫ����
    hidden_layer_num=2*input_num+1;%��������Ԫ����
    output_num=cell{i,j}.route_num+1;%�������Ԫ����
    if t==1
        for ii=1:N_agent_length
            for jj=1:N_agent_length
                %========������з�ʽѡ�����========================
                cell{i,j}.cell{ii,jj}.input=[cell{i,j}.bus_fee(1:end),cell{i,j}.car_fee];%�����������
                cell{i,j}.cell{ii,jj}.W1=-1+(1+1)*rand(input_num,hidden_layer_num);%�������������֮��Ȩ��
                cell{i,j}.cell{ii,jj}.W2=-1+(1+1)*rand(hidden_layer_num,output_num);%��������������Ȩ��
                cell{i,j}.cell{ii,jj}.output=cell{i,j}.cell{ii,jj}.input*cell{i,j}.cell{ii,jj}.W1*cell{i,j}.cell{ii,jj}.W2;%����������
                %========sigmoid������һ��========
                cell{i,j}.cell{ii,jj}.sig_output=1./(1+exp(-cell{i,j}.cell{ii,jj}.output));%sigmoid����
                cell{i,j}.cell{ii,jj}.sum_sig=sum(cell{i,j}.cell{ii,jj}.sig_output);
                cell{i,j}.cell{ii,jj}.new_output=cell{i,j}.cell{ii,jj}.sig_output./cell{i,j}.cell{ii,jj}.sum_sig;%���ʺ�Ϊ1
                for ss=1:output_num
                    q_cell(ss,ii,jj)=cell{i,j}.cell{ii,jj}.new_output(ss);
                end
%                 rand_mode=rand;
%                 for s=1:output_num
%                     sum_mode(s)=sum(cell{i,j}.cell{ii,jj}.new_output(1:s));
%                 end
%                 if rand_mode<=sum_mode(1)
%                     cell{i,j}.cell{ii,jj}.mode=1;
%                 end
%                 for s=2:output_num
%                     if rand_mode>sum_mode(s-1)&&rand_mode<=sum_mode(s)
%                         cell{i,j}.cell{ii,jj}.mode=s;
%                     end
%                 end
            end
        end
        %========�������=============
        cell{i,j}.car_q=mean(mean(q_cell(output_num,:,:)))*OD(i,j);
        for ss=1:output_num-1
            cell{i,j}.bus_q(ss)=mean(mean(q_cell(ss,:,:)))*OD(i,j);
        end
    end
    %=========ÿ��Ԫ���������ߣ�Ԥ��������==========
    for ii=1:N_agent_length
        for jj=1:N_agent_length
            cell{i,j}.cell{ii,jj}.input=[cell{i,j}.bus_fee(1:end),cell{i,j}.car_fee];%�����������
            for s=1:output_num
                cell{i,j}.cell{ii,jj}.fee(s)=cell{i,j}.cell{ii,jj}.input(s)*cell{i,j}.cell{ii,jj}.new_output(s);%��Ȩ���з���
            end
            cell{i,j}.cell{ii,jj}.g_fee=sum(cell{i,j}.cell{ii,jj}.fee);%�����ܳ��з���
        end
    end
    %=========ѧϰ������ѧϰ��Χ�ľ��飩=================
    for ii=2:N_agent_length-1
        for jj=2:N_agent_length-1
            %======�ռ���Χ��Ϣ=====
            i_index=1;
            for pp=ii-1:ii+1
                for qq=jj-1:jj+1
                    cell{i,j}.cell{ii,jj}.experience(i_index,:)=[cell{i,j}.cell{pp,qq}.g_fee,pp,qq];
                    i_index=i_index+1;
                end
            end
            %========��λ����Χ��õľ���=========
            cell{i,j}.cell{ii,jj}.best=find(cell{i,j}.cell{ii,jj}.experience==min(cell{i,j}.cell{ii,jj}.experience(:,1)));
            best_index=cell{i,j}.cell{ii,jj}.best;
            best_x=cell{i,j}.cell{ii,jj}.experience(best_index,2);
            best_y=cell{i,j}.cell{ii,jj}.experience(best_index,3);
            %=======ѧϰ����==============
            cell{i,j}.cell{ii,jj}.W1=(1-theita_l_so)*cell{i,j}.cell{ii,jj}.W1+theita_l_so*cell{i,j}.cell{best_x(1),best_y(1)}.W1;
            cell{i,j}.cell{ii,jj}.W2=(1-theita_l_so)*cell{i,j}.cell{ii,jj}.W2+theita_l_so*cell{i,j}.cell{best_x(1),best_y(1)}.W2;
            %=======������з�ʽѡ�����=======
            cell{i,j}.cell{ii,jj}.output=cell{i,j}.cell{ii,jj}.input*cell{i,j}.cell{ii,jj}.W1*cell{i,j}.cell{ii,jj}.W2;%����������
            %========sigmoid������һ��========
            cell{i,j}.cell{ii,jj}.sig_output=1./(1+exp(-cell{i,j}.cell{ii,jj}.output));%sigmoid����
            cell{i,j}.cell{ii,jj}.sum_sig=sum(cell{i,j}.cell{ii,jj}.sig_output);
            cell{i,j}.cell{ii,jj}.new_output=cell{i,j}.cell{ii,jj}.sig_output./cell{i,j}.cell{ii,jj}.sum_sig;%���ʺ�Ϊ1
            
        end
    end
    for ii=1:N_agent_length
        for jj=1:N_agent_length
            for ss=1:output_num
                q_cell(ss,ii,jj)=cell{i,j}.cell{ii,jj}.new_output(ss);
            end 
        end
    end
    %========�������=============
    cell{i,j}.car_q=mean(mean(q_cell(output_num,:,:)))*OD(i,j);
    for ss=1:output_num-1
        cell{i,j}.bus_q(ss)=mean(mean(q_cell(ss,:,:)))*OD(i,j);
    end
end
end



