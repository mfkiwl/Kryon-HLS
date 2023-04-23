`timescale 1ns / 1ps
//�������ԣ�https://github.com/becomequantum  ������ȥ���� /�Ƽ��鼮 Ŀ¼�µ����ݣ���2022�������ָ�ϡ�����д��һЩ�޷������������ݡ�
//����������Ƶ��
//https://www.bilibili.com/video/BV1QY411V7Pg  �����Լ��Ķ���˼�������ȿ�������д�Ĵ������Ҫ�������޴�Ԫ��Ƶ���û�ж���˼����������ֻ�ǿɱ�̻����ˣ�����Щ��̸����Ƶ����Ҫ��
//https://www.youtube.com/watch?v=dE5gn4jkSbw

module Histogram #(
   parameter  DATA_WIDTH = 8,               //��������λ��һ����8λ��
   parameter  CNT_WIDTH = 18                //��������λ��
   )
   (
    input clk,
    input VSYNC,                            //��ֱͬ���źţ�Ҳ����֡��Ч�źţ�����ָʾһ֡����֮���������Ram������ݣ��ⲿ�����������ûд
    input DataEn,                           //DE,������Ч�ź�
    input [DATA_WIDTH - 1 : 0] PixelData    //��������
    );
    wire [CNT_WIDTH - 1 : 0] Cnt, CntPlus1;
    reg [DATA_WIDTH - 1 : 0] addrb;
    reg web;
    
    always@(posedge clk) begin
      web <= DataEn;
      addrb <= PixelData;
    end
    
    assign CntPlus1 = Cnt + 1;           
    
    CountArray iCountArray (
      .clka(clk),            // input wire clka
      .wea(1'b0),            // a����Ϊ���˿ڣ�����дʹ�����㡣
      .addra({0, PixelData}),// PixelDataֻ��8λ��addra��10λ������ǰ��Ҫ�Ӹ�0����λ������Ȼû����ĸ�λ�������յ�X���ᵼ�·������
      .dina(0),              // д����Ҳ��Ϊ0�����õ�����Ҫ���㣬���ܿ���
      .douta(Cnt),           // output wire [17 : 0] douta
      .clkb(clk),            // input wire clkb
      .web(web),             // input wire [0 : 0] web
      .addrb({0,addrb}),     // input wire [9 : 0] addrb   û��дn'b0ע��λ��ʱ��Ĭ��Ϊ32λ
      .dinb(CntPlus1),       // input wire [17 : 0] dinb
      .doutb()               // ���û���Ͽ��ž��� 
    );    
endmodule
