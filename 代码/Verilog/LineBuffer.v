`timescale 1ns / 1ps
//���������ԣ�github.com/becomequantum/Kryon
//��������Ƶ��www.bilibili.com/video/BV1B3411W7Ht
//��ģ����������ͼ�����ݵĻ���. ����ͼ������, ���OPERATOR_HEIGHT����������, ������Block Ram�Ķ�д. �˺���ģ��.
module LineBuffer
   #(                                                                   //����д�Ĳ�����Ĭ��ֵ,��������ģ���ʱ����Ը�����Ҫ�޸�
   parameter DATA_WIDTH      =  8,                                      //��������λ��һ����8λ��Ҳ������10��12��14λ����ֵͼ�����1λ. The pixel data bit width is generally 8 bits, or 10, 12, and 14 bits. The binary image is 1 bits.
   parameter ADDR_WIDTH      = 11,                                      //����ͼ���Block RAM��ַλ��,��ͼ�����й�,2^11=2048
   parameter OPERATOR_HEIGHT =  3                                       //���ӵĸ߶�,NxN�������������ΪN
   )
   (
    input                                               clk           ,
    input                                               DataEn        , //�������ݵ�Enable�ź�
    input  [DATA_WIDTH - 1                         : 0] PixelData     , //��������               
    output [ADDR_WIDTH - 1                         : 0] addra         , //����Ϊ������дBlock Ram���ź�,a�˿ڶ���,b�˿�д��    
    input  [(OPERATOR_HEIGHT - 1) * DATA_WIDTH - 1 : 0] douta         , //N�е�����ֻ��Ҫ����N-1�е�����. The N line operator only needs to buffer N-1 lines' data  
    output                                              web           ,
    output [ADDR_WIDTH - 1                         : 0] addrb         ,
    output [(OPERATOR_HEIGHT - 1) * DATA_WIDTH - 1 : 0] dinb          ,
    output                                              OperatorDataEn, //���OPERATOR_HEIGHT���������� 
    output [OPERATOR_HEIGHT * DATA_WIDTH - 1       : 0] OperatorData    
    );
    
    reg    [ADDR_WIDTH - 1                         : 0] FrogCount = 0  ;//FPGA��ļĴ������Ը���ʼֵ,������غ���ǳ�ʼֵ,����һ�㲻��Ҫreset�ź�. Registers in FPGA can be assigned initial values, and the initial values are loaded after programs are loaded, so reset signals are generally not required.      
    reg    [DATA_WIDTH - 1                         : 0] PixelDataReg   ;
    reg    [OPERATOR_HEIGHT * DATA_WIDTH - 1       : 0] OperatorDataReg;
    reg    [1                                      : 0] DataEnReg      ;
    
    assign addra          = FrogCount      ,
           OperatorData   = OperatorDataReg,
           OperatorDataEn = DataEnReg[1]   ,                            //������ʱ����������,ʹ���ź�ҲҪ��ʱ2������. The data is delayed by two cycles, so enable signal also needs to be delayed for 2 cycles.
           addrb          = FrogCount - 2  ,                            //��Ϊ������ʱ����������,����д�ص�ַҪ�ö���ַ����. Because the data has been delayed for two cycles, the read address should minus two.
           web            = DataEnReg[1]   ,
           dinb           = OperatorDataReg[OPERATOR_HEIGHT * DATA_WIDTH - 1 : DATA_WIDTH];  
                                                                        //�ٴ��Ram������Ҫ�����µ�һ���ƽ�ȥ,���ϵ�һ���Ƴ�.��λΪ������,Ҳ��������������һ�е�����. Shift out the oldest data.
    always@(posedge clk)
    begin
      if(DataEn || OperatorDataEn)
        FrogCount     <= FrogCount + 1;                                 //�������Բ�����дRam�ĵ�ַ. Generate Ram reading address
      else            
        FrogCount     <= 0;
      PixelDataReg    <= PixelData;                                     //���ڶ�ȡRam��֮ǰ��������ݻ��������������һ������,����Ҫ�����������ݼĴ�һ�����ںúͶ��������ݶ���
      OperatorDataReg <= {PixelDataReg,douta};                          //�Ѷ�����֮ǰ��������ݺ���һ�е����ݺϲ���N�������������,�����������������ʱ��һ������,����ʱ��������, ��һ���Ĵ�������ȡ����Ҫ��
      DataEnReg[0]    <= DataEn;                                        //����Ҫ��ʱʹ���ź��������ڡ����OperatorDataReg��һ���Ĵ�����Ҫ�ˣ���ʱ��Ϊ1�����ڡ�
      DataEnReg[1]    <= DataEnReg[0];
    end 
    
endmodule
//������ֻ�дӾ²�����Ϊ��Ѫ��ͷ�����Ƽ��������Ƽ��鼮��Ŀ¼������ݡ�