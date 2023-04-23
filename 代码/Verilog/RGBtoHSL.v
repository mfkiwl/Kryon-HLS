`timescale 1ns / 1ps
//���������ԣ�github.com/becomequantum/Kryon 
//������ʵ�ֵľ���"���޴�Ԫ"C#������"ͼ��.cs"������"RGBתHSL"�������
//���뽲����Ƶ: www.bilibili.com/video/BV1MS4y1r76o
module RGBtoHSL(
    input clk,
    input RGBEn,
    input [7:0] R,
    input [7:0] G,
    input [7:0] B,
    output HSLEn,
    output reg [7:0] H,
    output reg [7:0] S,
    output reg [7:0] L
    );
	 //��׺_n������������RGB�����ӳ���n�����ڡ�������ͬ�ӳٵı������ܷ���һ�����㣬�����ú�׺������ʱ�Է�����
	 reg [7:0] max_1, min_1, diff_2, R_1, G_1, B_1, max_y_2, max_z_2; 
	 reg [8:0] sum_2;
	 reg [1:0] maxIndex_1, maxIndex_2;     
	 
	 //�Ȱ�R��G��B���ĸ�����ĸ���С�ȳ������ٰ������С�ĺͣ�sum_2���diff_2�����
	 wire [7:0] maxRG      = R > G ? R : G,
	            minRG      = R > G ? G : R;
    wire       maxIndexRG = R > G ? 0 : 1;			
	 
	 always@(posedge clk) begin
	   max_1 <= maxRG > B ? maxRG : B;   //RGB�е����ֵ
		min_1 <= minRG > B ? B : minRG;   //��Сֵ
		
		diff_2 <= max_1 - min_1;          
		sum_2  <= max_1 + min_1;          
		
		maxIndex_1 <= maxRG > B ? {1'b0,maxIndexRG} : 2;  
		maxIndex_2 <= maxIndex_1;         //���ڼ�¼RGB˭���R���Ϊ0��G���Ϊ1��B���Ϊ2
	 end
	 
	 //---����L����ֵ��L�����--- 
	 //L_2 = sum_2 * (24 / 51), 24/51 = 0.47 = 0.0_111100001, ��9λ���ȲŹ�, ֱ��д sum_2 * 0.47��������ȷ�����ۺϹ����ˣ����Գ�������DSP�˷�����
	 //����510�ٳ���240��Ҫ��L��ȡֵ����Ҳͳһ��0��240֮�䣬ԭ����0��255*2 = 510
	 wire [17:0] L_2 = (sum_2 << 8)+ (sum_2 << 7) + (sum_2 << 6) + (sum_2 << 5) + sum_2;//д��sum_2 * 9'b111100001 Ҳ����                
	 
	                         //3������¼��Ϊ0��H��SΪ0������      ����������λ��             ��������
	 wire [10:0] delayin_2 = {(diff_2 == 0) ? 2'd3 : maxIndex_2, y_z_2[8], L_2[17:10] + L_2[9]};
    wire [10:0] delayout_22;	 
	 
	  Delay20 d20 ( //���ڰ�Lֵ��RGB�ĸ����y_z_2���������������ź��ӳ�20�����ڣ��ͳ������ӳ���ͬ��L��Ȼֻ��2�����ھ������������������H��Sʱ����룬������Ҫ�ӳ١�
      .d(delayin_2), // input [10 : 0] d
      .clk(clk), // input clk
      .q(delayout_22) // output [10 : 0] q
	  );
	  
	  always@(posedge clk)
	    L <= delayout_22[7:0];     //���յ�L������ӳ���23������
	
	 
	 //---����S���Ͷ�ֵ---
	                        //Ԥ����ĸ�����㵼�½����ȷ��
	 wire [7:0] sdivisor_2 = (sum_2 == 9'd510 || sum_2 == 0) ? 1 : ((sum_2 < 9'd255) ? sum_2 : 9'd510 - sum_2);
	 wire [9:0] sfractional;
	 wire [7:0] squotient;
	 
	 Divider sDivider (//��ʱ20�����ڡ�Divider IP,�����������������ã�����������������8λ���޷��ţ�С������10λ��
	  .clk(clk),
	  .rfd(), //�ò���
	  .dividend(diff_2), // input [7 : 0] dividend ����������diff_2
	  .divisor(sdivisor_2), // input [7 : 0] divisor
	  .quotient(squotient), // output [7 : 0] quotient
	  .fractional(sfractional)); // output [9 : 0] fractional
	
    wire [17:0] S_22 = {squotient[0],sfractional} * 8'd240;  //squotient�̻�Ҫȡһλ����Ϊ���п���Ϊ1��	
	 
	 always@(posedge clk)
	   S <= S_22[17:10] + S_22[9]; //S����������Ӻ���һλ������������
		

   //---����Hɫ��ֵ---
	always@(posedge clk) begin
	   R_1 <= R; G_1 <= G; B_1 <= B; //��ʱһ�����������������max_1 - RGB_1, ��Ϊmax_1����һ�����ڣ�����Ҳ�����R��G��B��һ������
		
		if(maxIndex_1 == 2'b0) begin
        max_y_2 <= max_1 - B_1;
		  max_z_2 <= max_1 - G_1;	
   	end
		if(maxIndex_1 == 2'b1) begin
        max_y_2 <= max_1 - R_1;
		  max_z_2 <= max_1 - B_1;	
   	end
		if(maxIndex_1 == 2'd2) begin
        max_y_2 <= max_1 - G_1;
		  max_z_2 <= max_1 - R_1;	
   	end 
	 end
	 
	 wire [8:0] y_z_2 = max_y_2 - max_z_2;
	 
	 wire [9:0] yzfractional;
	 wire [7:0] yzquotient;
	 wire [7:0] yzdividend_2 = y_z_2[8] ? (~y_z_2[7:0] + 1) : y_z_2[7:0]; //ȡ����ֵ���㣬��Ϊ���������޷��ŵģ�
	  
	 Divider yzDivider ( //���ú�ǰ��ĳ�����һ��
	  .clk(clk), // input clk
	  .rfd(), // output rfd
	  .dividend(yzdividend_2), // input [7 : 0] dividend
	  .divisor(diff_2), // input [7 : 0] divisor
	  .quotient(yzquotient), // output [7 : 0] quotient
	  .fractional(yzfractional)); // output [9 : 0] fractional
	 

    wire [1:0] maxIndex_22 = delayout_22[10:9]; //���ڼ�¼RGB˭���R���Ϊ0��G���Ϊ1��B���Ϊ2��Ϊ3ʱRGB����ȣ�H��SΪ�㡣�ӳ���20�����ں��ܹ��ӳ�22�����ڡ�
    wire sign_22 = delayout_22[8];	 
	 wire [7:0] Hbias = 80 * maxIndex_22;        //ɫ��ֵƫ��: ��Ϊ0����Ϊ80����Ϊ160
    
    wire [17:0] H_22 = {yzquotient[0],yzfractional} * 40;  //�������Ľ����0��1����ĵģ�����40����0��40����
	 
	 wire [10:0] Hb_22 = sign_22 ? {Hbias,2'b0} - H_22[17:8] : {Hbias,2'b0} + H_22[17:8]; //�������Żָ���������ɫ��ֵƫ��: ��Ϊ0����Ϊ80����Ϊ160
	 
	 wire [7 :0] Hround_22 = Hb_22[9:2] + Hb_22[1];     //��������
	 
	 wire [10:0] H240_22 = {1'b0,8'd240,2'b0} + Hb_22;  //�������桰С����ͼ�240���������
	 
	 always@(posedge clk) begin
	   if(maxIndex_22 == 2'd3)   //maxIndexΪ3ʱRGB����ȣ�H������
		  H <= 0;
		else if(Hb_22[10] == 1)   //С����ͼ�240
		  H <= H240_22[9:2] + H240_22[1];
		else if(Hround_22 > 240 && (Hb_22[10] == 0)) //����240�ͼ�240
		  H <= Hround_22 - 240;
		else
		  H <= Hround_22;
	 end
	 
	 //����ʹ���ź�Ҳ�ӳ���Ӧ�����ں�HSL����źŶ���
	 Delay23 EnDelay (//IP: Ram based Shift-Register 
     .d(RGBEn), // input [0 : 0] d
     .clk(clk), // input clk
     .q(HSLEn) // output [0 : 0] q
    );
    
endmodule
