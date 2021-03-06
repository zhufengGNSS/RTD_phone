function [satPositions, satClkCorr, eph] = GPS_calculateSatPosition(transmitTime, ephemeris, activeChannel)
%星历参数
%satPositions [6*satnum],each colunm [x,y,z,vx,vy,vz]'
%satClkCorr [1*satnum],
%prnList = [14 13 10 8 6 5 4 3 2 1]; % the satellite number
%activeChannel: the active channels
% initial
satPositions = zeros(6,32);
satClkCorr=zeros(2,32);     % 1位钟差， 2为频飘
for i = 1:length(activeChannel)
    eph(activeChannel(i)) = ephemeris(activeChannel(i)).eph;
end
numOfSatellites = length(activeChannel);
% TODO: modify the codes here to be more concise
% activeCH_Num = length(activeChannel);
% prnList(1:activeCH_Num) = activeChannel(1:activeCH_Num);

%miu=3.986004418e14;%CGS2000坐标系下的地球引力常数(m^3/s^2)
OMEGA_dot=7.2921151467e-5;%CGS2000坐标系下的地球旋转速率(rad/s)
GM=3.986004418e14;%CGS2000坐标系下的地球引力常数(m^3/s^2)
pi=3.1415926535898;
F = -4.442807633e-10; % Constant, [sec/(meter)^(1/2)]
%%%% for test
%transmitTime = time;
%%%%
for satNr = 1 : numOfSatellites
    
    prn = activeChannel(satNr);
    
    toe=eph(prn).toe;%星历参考时间
    sqrtA=eph(prn).sqrtA;%长半轴的平方根
    e=eph(prn).e;%偏心率
    omega=eph(prn).omega;%近地点幅角
    deltan=eph(prn).deltan;%卫星平均运动速率与计算值之差
    M0=eph(prn).M0;%参考时间的平近点角
    omega0=eph(prn).omega0;%按参考时间计算的升交点经度
    omega_dot=eph(prn).omegaDot;%OMEGA_DOT%升交点经度变化率
    i0=eph(prn).i0;%参考时间的轨道倾角
    iDot=eph(prn).iDot;%轨道倾角变化率
    Cuc=eph(prn).Cuc;%纬度幅角的余弦调和改正项的振幅
    Cus=eph(prn).Cus;%纬度幅角的正弦调和改正项的振幅
    Crc=eph(prn).Crc;%轨道半径的余弦调和改正项的振幅
    Crs=eph(prn).Crs;%轨道半径的正弦调和改正项的振幅
    Cic=eph(prn).Cic;%轨道倾角的余弦调和改正项的振幅
    Cis=eph(prn).Cis;%轨道倾角的正弦调和改正项的振幅
    
    toc=eph(prn).toc; %!!!!!!!!!!!!!!!!!causion
    a0=eph(prn).af0;
    a1=eph(prn).af1;
    a2=eph(prn).af2;
    %transmitTime=eph(prn).SOW;
    TGD1=eph(prn).TGD;
    %% find initial satellite clock correction
    %%%%%%%%修正发射时间
    dt = check_t(transmitTime(prn)-toc);
    % dt = check_t(transmitTime-toc);
    %%%%%%计算卫星测距码相位时间偏差
    satClkCorr(1,prn) = a0+(a1+a2*dt)*dt-TGD1;
    %%%%%%%%%计算相对论校正项
    %%%%%%%%%%%%%%%%计算信号发射时刻系统时间
    time = transmitTime(prn) - satClkCorr(1,prn);
    %% find sat position
    %计算半长轴
    A=sqrtA^2;
    %时间校正
    tk  = check_t(time - toe);
    %计算卫星平均角速度
    n0=(GM/A^3)^0.5;
    %计算观测历元到参考历元的时间差
    %t_k=t-toe;%t?
    %改正平均角速度
    n=n0+deltan;
    %计算平近点角
    % if t-toe>302400;
    %     t=t-604800;
    % else if t-toe<-302400;
    %     t=t+604800;
    %     end
    % end
    %t_k=t-toe;
    %M_k=M0+n*t_k;
    M=M0+n*tk;
    M   = rem(M + 2*pi, 2*pi);
    
    %迭代计算偏近点角,超越方程
    %Eold=M_k;
    % error=1;
    % while error>1e-12;
    %     E=M_k-e*sin(Eold);
    %     error=abs(E-Eold);
    %     Eold= E;
    % end
    E=M;
    %--- Iteratively compute eccentric anomaly ----------------------------
    for ii = 1:10
        Eold   = E;
        E       = M + e * sin(E);
        dE      = rem(E - Eold, 2*pi);
        
        if abs(dE) < 1.e-12
            % Necessary precision is reached, exit from the loop
            break;
        end
    end
    
    E   = rem(E + 2*pi, 2*pi);
    %M_k=E-e*sin(E);
    %时间修正
    %相对论修正项
    dtr = F*e*sqrtA * sin(E);
    %总时间修正项
    %%%%%%%%%%%进行一次反馈再次计算%%%%%%%%%%
    satClkCorr(1,prn)=a0+(a1+a2*dt)*dt+dtr-TGD1;
    time = transmitTime(prn) - satClkCorr(1,prn);
    %时间校正
    tk  = check_t(time - toe);
    %计算卫星平均角速度
    n0=(GM/A^3)^0.5;
    %计算观测历元到参考历元的时间差
    %t_k=t-toe;%t?
    %改正平均角速度
    n=n0+deltan;
    %计算平近点角
    % if t-toe>302400;
    %     t=t-604800;
    % else if t-toe<-302400;
    %     t=t+604800;
    %     end
    % end
    %t_k=t-toe;
    %M_k=M0+n*t_k;
    M=M0+n*tk;
    M   = rem(M + 2*pi, 2*pi);
    
    %迭代计算偏近点角,超越方程
    %Eold=M_k;
    % error=1;
    % while error>1e-12;
    %     E=M_k-e*sin(Eold);
    %     error=abs(E-Eold);
    %     Eold= E;
    % end
    E=M;
    %--- Iteratively compute eccentric anomaly ----------------------------
    for ii = 1:10
        Eold   = E;
        E       = M + e * sin(E);
        dE      = rem(E - Eold, 2*pi);
        
        if abs(dE) < 1.e-12
            % Necessary precision is reached, exit from the loop
            break;
        end
    end
    
    E   = rem(E + 2*pi, 2*pi);
    %%%%%%%%%%%进行一次反馈再次计算%%%%%%%%%%
    % t_k=transmitTime-toe;
    % dt=a0+(a1+a2)*t_k+dtr-TGD1;
    % transmitTime=transmitTime-dt;
    %%%修正
    %t=t-TGD1;
    %%%%%
    %t_k=t-toe;
    %计算真近点角
    %v_k2=asin(((1-e^2)^0.5*sin(E))/(1-e*cos(E)));
    %v_k1=acos((cos(E)-e)/(1-e*cos(E)));
    %v_k=v_k1*sign(v_k2);
    
    v_k   = atan2(sqrt(1 - e^2) * sin(E), cos(E)-e);
    %计算纬度幅角参数
    phi_k=v_k+omega;
    %Reduce phi to between 0 and 360 deg
    phi_k = rem(phi_k, 2*pi);
    %计算周期改正项，纬度幅角改正项、径向改正项、轨道倾角改正项
    delta_u_k=Cus*sin(2*phi_k)+Cuc*cos(2*phi_k);
    delta_r_k=Crs*sin(2*phi_k)+Crc*cos(2*phi_k);
    delta_i_k=Cis*sin(2*phi_k)+Cic*cos(2*phi_k);
    %计算改正后的纬度参数
    u_k=phi_k+delta_u_k;
    %计算改正后的径向
    r_k=A*(1-e*cos(E))+delta_r_k;
    %计算改正后的倾角
    i_k=i0+iDot*tk+delta_i_k;
    %计算卫星在轨道平面内的坐标
    x_k=r_k.*cos(u_k);
    y_k=r_k.*sin(u_k);
    %% GEO
    % % if prn <=5 ;
    % % %计算历元升交点的经度（惯性系），计算GEO卫星在自定义惯性系中的坐标
    % % OMEGA_k=omega0+omega*tk-OMEGA_dot*toe;
    % % X_k=x_k.*cos(OMEGA_k)-y_k.*cos(i_k).*sin(OMEGA_k);
    % % Y_k=x_k.*sin(OMEGA_k)+y_k.*cos(i_k).*cos(OMEGA_k);
    % % Z_k=y_k.*sin(i_k);
    % % %计算GEO卫星在CGS2000坐标系中的坐标
    % % %[X_GK;Y_GK;Z_GK] = R_Z(OMEGA_dot*tk)*R_X(-5)*[X_k;Y_k;Z_k];%-5度
    % % %positon=R_Z(OMEGA_dot*tk)*R_X(-5)*[X_k;Y_k;Z_k];%-5度
    % % position=[cos(OMEGA_dot*tk) sin(OMEGA_dot*tk) ...
    % %     0;-sin(OMEGA_dot*tk) cos(OMEGA_dot*tk) 0;0 0 1]*[1 ...
    % %     0 0;0 cos(-pi/36) sin(-pi/36);0 -sin(-pi/36) cos(-pi/36)]*[X_k;Y_k;Z_k];%-5度
    % % X_GK=position(1);
    % % Y_GK=position(2);
    % % Z_GK=position(3);
    %NGEO(satNr)
    % % else
    %计算历元升交点的经度（地固系），计算MEO/IGSO卫星在CGS2000坐标系中的坐标
    OMEGA_k=omega0+(omega_dot-OMEGA_dot)*tk-OMEGA_dot*toe;
    X_k=x_k.*cos(OMEGA_k)-y_k.*cos(i_k).*sin(OMEGA_k);
    Y_k=x_k.*sin(OMEGA_k)+y_k.*cos(i_k).*cos(OMEGA_k);
    Z_k=y_k.*sin(i_k);
    position = [X_k;Y_k;Z_k];
    % % end
    %%
    satPositions(1, prn) = position(1);
    satPositions(2, prn) = position(2);
    satPositions(3, prn) = position(3);
    % satPositions(4, satNr) = 0;
    % satPositions(5, satNr) = 0;
    % satPositions(6, satNr) = 0;
    %% calculate velocity of NGEO satellite
    % % if prn > 5
    %==============start calculate velocity===========================
    %1.计算E的倒数,倒数全采用下标1表示，E1
    E1 = n/(1-e*cos(E));
    %2.计算phi_k的倒数phi_k1，phi_k1=v_k1
    phi_k1 = sqrt(1-e*e)*E1/(1-e*cos(E));
    %3.计算delta_u_k1，delta_r_k1，delta_i_k1
    delta_u_k1 = 2*phi_k1*(Cus*cos(2*phi_k)-Cuc*sin(2*phi_k));
    delta_r_k1 = 2*phi_k1*(Crs*cos(2*phi_k)-Crc*sin(2*phi_k));
    delta_i_k1 = 2*phi_k1*(Cis*cos(2*phi_k)-Cic*sin(2*phi_k));
    %4.计算u_k1,r_k1,i_k1,OMEGA_k1
    u_k1 = phi_k1 + delta_u_k1;
    r_k1 = A*e*E1*sin(E) + delta_r_k1;
    i_k1 = iDot + delta_i_k1;
    OMEGA_k1 = omega_dot-OMEGA_dot;
    %5.计算x_k1,y_k1
    x_k1 = r_k1*cos(u_k) - r_k*u_k1*sin(u_k);
    y_k1 = r_k1*sin(u_k) + r_k*u_k1*cos(u_k);
    %6.计算X_k1,Y_k1,Z_k1即vx,vy,vz
    X_k1 = -Y_k*OMEGA_k1-(y_k1*cos(i_k)-Z_k*i_k1)*sin(OMEGA_k)+x_k1*cos(OMEGA_k);
    Y_k1 = X_k*OMEGA_k1+(y_k1*cos(i_k)-Z_k*i_k1)*cos(OMEGA_k)+x_k1*sin(OMEGA_k);
    Z_k1 = y_k1*sin(i_k) + y_k*i_k1*cos(i_k);
    %==============finish calculate velocity==========================
    satPositions(4, prn) = X_k1;
    satPositions(5, prn) = Y_k1;
    satPositions(6, prn) = Z_k1;
    % % else
    % %   satPositions(4, prn) = 0;
    % %   satPositions(5, prn) = 0;
    % %   satPositions(6, prn) = 0;
    % % end
    %%
    %R_X(phi)=[1 0 0;0 cos(-5) sin(-5);0 -sin(-5) cos(-5)];
    %R_Z(phi)=[cos(OMEGA_dot*tk) sin(OMEGA_dot*tk) ...
    %   0;-sin(OMEGA_dot*tk) cos(OMEGA_dot*tk) 0;0 0 1];
    %R_X(phi)=[1 0 0;0 cos(phi) sin(phi);0 -sin(phi) cos(phi)];
    %R_Z(phi)=[cos(phi) sin(phi) 0;-sin(phi) cos(phi) 0;0 0 1];
    
    %表达式中，t是信号发射时刻的BD-2系统时间，也就是对传播时间修正后的BD-2系统接收时间（距离/光速）。
    %因此，t_k就是BD-2系统时间t和星历参考时间toe之间的总时间差，并考虑了跨过一周开始或结束的时间，
    %也就是：如果t_k>302400时，就从t_k中减去604800；而如果t_k<-302400时，就对t_k中加上604800
    %satposition(satNr)=[X_GK;Y_GK;Z_GK];
    dtr = F*e*sqrtA * sin(E);
    satClkCorr(1,prn)=a0+(a1+a2*dt)*dt+dtr-TGD1;
    dtr_dot = F*e*sqrtA * E1 * cos(E);
    satClkCorr(2,prn) = a1 + 2*a2*dt + dtr_dot;
end


