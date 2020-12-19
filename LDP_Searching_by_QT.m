
% Written by Teng Qiu
% A: the data set

function [neighborIds,supk,nb,rho,local_core,cores,cl,ini_cluster_number] = LDP_Searching_by_QT(A,knnMethod,initial_max_k)
[N,dim]=size(A);
disp('determine the inital k nearest neighbors...');

% % Note: knnsearch uses the exhaustive search method by default to find the k-nearest neighbors: The number of columns of X is more than 10.
% % knnsearch uses the kd-tree search method by default to find the k-nearest neighbors: The number of columns of X is less than or equal to 10.
 
    
distance_function = 'euclidean';
 switch knnMethod
    case 'kd_tree'
        constructed_search_tree = createns(A,'NSMethod','kdtree','Distance',distance_function);
        [neighborIds, knnD] = knnsearch(constructed_search_tree,A,'k',initial_max_k);
    case 'hnsw' 
        file_name = 'HnswConstructionforCurrentData'; % file_name can be named in other ways that one like.
        MatlabHnswConstruct(single(A),file_name,distance_function); % for hnsw, its distance function only supports: 'euclidean','l2','cosine','ip';
        [neighborIds, knnD] = MatlabHnswSearch(single(A),initial_max_k,file_name,distance_function);
        neighborIds = double(neighborIds);
        knnD = double(knnD);
end

%��ʼ����������
supk=1;
flag=0;
nb=zeros(1,N);  %��Ȼ�ھӸ���
%NNN=zeros(N,N); %�������Ȼ�ھӼ�
count=0;        %��Ȼ�������Ϊ���������������ͬ�Ĵ���
count1=0;       %ǰһ����Ȼ�������Ϊ��������� 

disp('Search natural neighbors...');
while flag==0
    for i=1:N
        q=neighborIds(i,supk+1);
        nb(q)=nb(q)+1;
    end
    supk=supk+1;
    count2=sum(nb==0);
    %����nb(i)=0�ĵ�������������仯�Ĵ���
    if count1==count2
        count=count+1;
    else
        count=1;
    end
    if count2==0 || (supk>2 && count>=2) || supk == initial_max_k   %�ھ�������ֹ����
        flag=1;
    end
    count1=count2;
 
end


%������Ȼ����ڵĸ���������
supk=supk-1;               %����Kֵ��Ҳ����Ȼ����ھӵ�ƽ����
max_nb=max(nb);         %��Ȼ�ھӵ������Ŀ

% if initial_max_k < max_nb + 1
%     initial_max_k = max_nb+1;
%     switch knnMethod
%         case 'kd_tree'
%             [neighborIds, knnD] = knnsearch(constructed_search_tree,A,'k',initial_max_k);
%         case 'hnsw'
%             [neighborIds, knnD] = MatlabHnswSearch(single(A),initial_max_k,file_name,distance_function);
%             neighborIds = double(neighborIds);
%             knnD = double(knnD);
%     end
% end
 

disp(['max_nb = ',num2str(max_nb),' supk = ',num2str(supk)]);

disp('Search local density peaks...');
dist_sum = sum(knnD,2);
rho=nb./dist_sum';

[max_density_unused,max_ind] = max(rho(neighborIds(:,1:supk+1)),[],2);
local_core=zeros(N,1);
for i=1:N
    local_core(i) = neighborIds(i,max_ind(i));
end

% find root for each node
% disp('find root for each node...');
% local_core_update = local_core(local_core);
% while any(local_core~=local_core_update)
%     local_core=local_core_update;
%     local_core_update = local_core(local_core);
% end

disp('find root for each node...');
local_core_update = local_core; 
while 1
    for i = 1:N
        local_core(i) = local_core(local_core(i));
    end
    if all(local_core==local_core_update)
        break
    else 
        local_core_update = local_core; 
    end
end


disp('initial clustering labeling (cluster label: 1,2,...#roots) ...');
cores = find(local_core' == 1:N); % cores: i.e., root nodes
ini_cluster_number = length(cores);
cl=zeros(N,1);
cl(cores) = 1:ini_cluster_number;
cl=cl(local_core);

neighborIds = neighborIds(:,1:supk+1);
end



