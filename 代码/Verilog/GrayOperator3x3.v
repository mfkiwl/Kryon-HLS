`timescale 1ns / 1ps
//���������ԣ�github.com/becomequantum/Kryon
//��������Ƶ��www.bilibili.com/video/BV1B3411W7Ht
//��ģ����3x3,8λ�Ҷ�ͼ�����ӵ�ʾ��,���������ӿ������ܶ�����.�����˲�,ƽ��,��Ե����,Ҳ�����ڴ��������Raw���ݵ�Bayer��ֵ.
//This module is an example of the 3x3, 8 bit gray image operator. Operators like this can do a lot of things, such as filtering, smoothing, edge detection, etc., and can also be used for Bayer interpolation of Raw data from image sensor output.
//���²����ɸ�����Ҫ�޸� The following parameters can be modified as required
`define DATA_WIDTH        8         //ͼ������λ��,��ģ��ʾ������8λ�Ҷ�����,����������Ϊ8  Image data bit width, this example is 8 bit grayscale operator, so here is 8. 
`define OPERATOR_HEIGHT   3         //���Ӹ߶�,��ģ��Ϊ3x3����ʾ��,����������Ϊ3 The height of the operator, in this example it's 3
`define ADDR_WIDTH        11        //2^11 = 2048��֧��һ��2048����,             Maximum 2048 pixel per line, can be modified.

module GrayOperator3x3(
    input                       clk      ,
  //input Vsync,                                  //�������Bayer��ֵ�Ļ�����Ҫ����֡��Ч�ź�,��Ϊ��Ҫ֪��������һ���ǵڼ���   If use as Bayer interpolation, you also need to input the frame enable signal, because you need to know which line it is.   
    input                       DataEn   ,                                 
    input [`DATA_WIDTH - 1 : 0] PixelData,                                 
    output                      DataOutEn         //ֻ��ʾ��ģ��,����û��д���������,ʹ��ʱ��������� Add whatever output you want
    );
    
    wire [`OPERATOR_HEIGHT * `DATA_WIDTH - 1 : 0] OperatorData           ; //�����о���[23:0],����8λͼ������. This example is [23:0], three line of 8 bit image data.
    reg  [`DATA_WIDTH - 1                    : 0] GaussianBlur           ; 
    reg  [`DATA_WIDTH + 1                    : 0] Gx,Gy                  ; 
    wire [`DATA_WIDTH + 1                    : 0] Left,Right,Up,Down     ;
    reg  [`DATA_WIDTH - 1                    : 0] Array00,Array01,Array02, //3x3������������,�����5x5�����������Ҫд5x5��. 3x3 operator data array, if it is 5x5 operator, here needs to write a 5X5 array
                                                  Array10,Array11,Array12, //Array11Ϊ3x3���ӵ����ĵ�, Array11 is the center
                                                  Array20,Array21,Array22;    
    
    //�����ӽ��еļ���,��ͬ�ļ�����в�ͬ��Ч��.ע��,���Ҫ�ڽ��и�˹ƽ��֮���ٽ��б�Ե���,�Ǿ���Ҫ����������ģ��:
    //��һ��ģ�����ƽ��,��������뵽�ڶ���ģ����б�Ե���
    //Different calculations have different effects. Note that two such modules are needed if the edge detection is performed after the Gauss smoothing is carried out:
    //The first module dose smooth, and the result inputs to the second module for edge detection.
    always@(posedge clk)
    begin
    	GaussianBlur <= (Array00 >> 4) + (Array01 >> 3) + (Array02 >> 4) +  
    	                (Array10 >> 3) + (Array11 >> 2) + (Array12 >> 3) +
    	                (Array20 >> 4) + (Array21 >> 3) + (Array22 >> 4);     //��˹ƽ��(ģ��)�Ľ��,ע������������ҪС�Ľ�����.Gauss smoothing (blur) results, be careful of overflow.
    	                
    	Gx           <= Right >= Left ? Right - Left : Left - Right;          //����Sobel���Ӽ�Ȩ�͵ľ���ֵ Calculating the absolute value of weighted sum of the Sobel operator
    	Gy           <= Up    >= Down ? Up    - Down : Down - Up   ;
    end
    
    assign Left  = Array00 + {Array10,1'b0} + Array20,                      //����Sobel���Ӽ�Ȩ��. Calculating the weighted sum of the Sobel operator
           Right = Array02 + {Array12,1'b0} + Array22,                      //��������Ĳ���������ʱ���ǳ��������Գ�������ҪDSP�˷���  
           Up    = Array00 + {Array01,1'b0} + Array02,
           Down  = Array20 + {Array21,1'b0} + Array22;
    
    assign Sobel = Gx + Gy >= 400;                                          //Sobel���ӱ�Ե�����,�������ô��İ�,�����ο�. 
    
    reg    [2:0] DataEnReg;          //���ʹ���ź�Ҫ������ļ���������,������Ҫ��ʱ���ٸ����ں����ӵĴ�С�Լ����м���ʱ���˶��ټ��Ĵ����й�, Output enable signal mast be aligned with the output results, it's delay relates to the size of the operator and calcuation delay
    assign DataOutEn = DataEnReg[2]; //��ʾ������ʱ��3������, 3�е����ӻ����2�����ڵ���ʱ;�ټ��ϼ���ʱ��1��. 5�е����ӻ����3��,3Ϊ��������λ�� In this example, the delay is 3 cycles, the 3 column operator produces 2 cycles' delay, plus 1 cycle delay in calcuation. 5 column operator will produces 3 cycles' delay, 3 as the center position of the operator.
                                     //������޸������Ӵ�С�ͼ����еļĴ�������,����ܷ�����֤һ����ʱ��û��Ū��. If you modified the size of the operator or the register levels in the calculation, you must run simulation to verify if the delay is correct.
        
    always@(posedge clk)
    begin 
    	Array00 <= Array01; Array01 <= Array02;
    	Array10 <= Array11; Array11 <= Array12;
    	Array20 <= Array21; Array21 <= Array22;
    	{Array22,Array12,Array02} <= OperatorData;     //��λ�Ĵ����3x3������������,OperatorData�е�λ��Ӧ��������. Shift Reg to generate 3x3 gray operator data array, Lower bits in 'OperatorData' correspond to operator's upper part
    	DataEnReg[0]   <=  OperatorDataEn;             //��ʱʹ���ź�,�������ʱ�ǽ���LineBufferģ�������ʹ���ź�OperatorDataEn֮���
    	DataEnReg[2:1] <=  DataEnReg[1:0];             //Delay output enable signal, this delay is after 'LineBuffer' module's output enable signal 'OperatorDataEn'                                   
    end
     
    //LineBuffer��Block Ram����,������ģ����������ͼ�����ݵĻ�������N���������ݵĹ���
    //Instantiate module LineBuffer and BlockRam, They buffer image data and output N line data of the operator
    wire [`ADDR_WIDTH - 1                          : 0] addra,addrb;
    wire [(`OPERATOR_HEIGHT - 1) * `DATA_WIDTH - 1 : 0] douta, dinb;
    LineBuffer
    #(
      .DATA_WIDTH     (`DATA_WIDTH     ),
      .ADDR_WIDTH     (`ADDR_WIDTH     ),
      .OPERATOR_HEIGHT(`OPERATOR_HEIGHT)
    )
    i3LineBuffer
    (
      .clk           (clk           ),
      .DataEn        (DataEn        ),
      .PixelData     (PixelData     ),               
      .addra         (addra         ),
      .douta         (douta         ),
      .web           (web           ),
      .addrb         (addrb         ),
      .dinb          (dinb          ),                    
      .OperatorDataEn(OperatorDataEn),
      .OperatorData  (OperatorData  )    
    );
    
    //���Block Ram��Ҫ��������������Ӵ�С��ͼ��Ŀ��������,2048ΪRam���,��Ӧͼ����,������ͼ���ȴ���2048,�������ɸ����Ram��ע�ⲻҪ��ѡ����Ĵ�����
    //Ram�Ŀ����>= (���Ӹ߶� - 1) * ����λ��. ���������� >= (3 - 1) * 8 = 16 
    //You need to generate this Block Ram according to your operator's size and your image's width. 2048 is the depth of the Ram, correspond to image width,
    //if your image width > 2048, then you need to generate a deeper Ram
    //Ram width needs to >= (operator's height - 1) * Data width. In this example, Ram width needs to >= (3 - 1) * 8 = 16 
    BlockRam18x2048 iBlockRam18x2048 (
      .clka (clk  ),  // input  wire          clka
      .wea  (0    ),  // input  wire [0  : 0] wea     a�˿�������,����дʹ���ź�Ҫ���� a is reading port, so wea needs to be 0
      .addra(addra),  // input  wire [10 : 0] addra
      .dina (0    ),  // input  wire [17 : 0] dina
      .douta(douta),  // output wire [17 : 0] douta
      .clkb (clk  ),  // input  wire          clkb
      .web  (web  ),  // input  wire [0  : 0] web
      .addrb(addrb),  // input  wire [10 : 0] addrb
      .dinb (dinb ),  // input  wire [17 : 0] dinb
      .doutb(     )   // output wire [17 : 0] doutb
    );
endmodule
