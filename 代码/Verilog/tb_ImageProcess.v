  `timescale 1 ns / 1 ps
//���������ԣ�github.com/becomequantum/Kryon
//��������Ƶ��https://www.bilibili.com/video/BV1ZS4y1H7oQ
//����Ĳ��Լ�����ֱ�Ӷ�ȡ������bmpλͼ�ļ���Ϊ�������룬���ѷ�����Ҳд�뵽һ��λͼ�ļ��У��������������Ϳ���ֱ�Ӵ�λͼ�ļ��鿴���������ò��Լ�����ISE�������������û������ġ�
  module tb_ImageProcess();
	 reg clk,RGBEn;
	 reg [7:0] R, G, B, InBetween;
	 integer InBmpFile, OutBmpFile1, BmpWidth, BmpHeight, BmpByteCount, Stride, w, h, i2;
	 reg [7:0] BmpHeadMem[1:54];    //bmpλͼ�ļ�ͷ��С��54�ֽڣ���1��ʼ����Ϊ$fread�ƺ���û������mem�ĸ�λ���������ʱ�������ַ1�ϡ�
	 reg [7:0] PixelMem[1:4];
	 
	 BinaryOperator9x9 iBinaryOperator9x9 //��ֵ����
    (
     .clk      (clk   ),         
     .DataEn   (RGBEn),
     .PixelData(G == 255),               //�����ڣ�0��ǰ���ף�1
     .DataOutEn()    
    );
	 
	
	 always #5 clk = ~clk;
	 
	 initial begin
	  clk = 1; R = 0; G = 0; B = 0; RGBEn = 0; 
		
		InBmpFile = $fopen("input.bmp","r"); 
	  $fread(BmpHeadMem,InBmpFile);                                                //����λͼ�ļ�ͷ	
	  
	  BmpWidth = {BmpHeadMem[22],BmpHeadMem[21],BmpHeadMem[20],BmpHeadMem[19]};    //���ļ�ͷ�л�ȡͼƬ�Ŀ���
		BmpHeight = {BmpHeadMem[26],BmpHeadMem[25],BmpHeadMem[24],BmpHeadMem[23]};
		
    BmpByteCount = {BmpHeadMem[30],BmpHeadMem[29]} >> 3;		                     //һ��������3�ֽڻ���4�ֽڣ�24λ��32λbmp������
    
		if(BmpByteCount == 4 || (BmpWidth % 4 == 0))
		  Stride =  BmpWidth * BmpByteCount;
		else
		  Stride = ((BmpWidth * BmpByteCount) / 4 + 1) * 4;                           //����ʵ��ÿ��ͼ������ռ�õ��ֽ��� 
		  
		
		ImageSimInput;                                                               //����ͼ������������񣬶�ȡinput.bmp���ݣ���������VGAʱ����
		
		repeat(10)@(posedge clk);
		$fclose(InBmpFile);
		$finish;
	 end
	 
	 task ImageSimInput;
	 begin
		repeat(10)@(posedge clk);
		for(h = BmpHeight - 1; h >= 0; h = h - 1) begin           //�������һ�����ݴ����˺��棬�ļ�ͷ������ӵ�������������һ�е�
		  repeat(20)@(posedge clk);                               //�м��϶��������ͨ��ʶ���㷨���������������̫С��
		  $fseek(InBmpFile, 54 + Stride * h,0);                   //�Ѷ��ļ���λ�õ���ÿһ�����ݵĿ�ʼ
		  #1 RGBEn = 1;
		  for(w = 0; w < BmpWidth; w = w + 1) begin
		    $fread(PixelMem, InBmpFile, 1, BmpByteCount);         //$fread(�����ĸ�Mem, Ҫ�����ļ�, ����Mem���ĸ���ַ�ϣ���Ϊ0��1����1��ʼ����Ϊ2���2��ʼ��, �������ֽ�)
		    B = PixelMem[1]; G = PixelMem[2]; R = PixelMem[3]; 
			 @(posedge clk);
			 #1;
		  end
		  RGBEn = 0; R = 0; G = 0; B = 0;
		end
	
		for(h = 0; h < 1; h = h + 1) begin                        //��Ҫ�����ɼ�������ʹ���źţ�������Padding����Ϊ���ӵ����Ҳ����ʱ�����С�
		  repeat(5)@(posedge clk);  
		  #1 RGBEn = 1;
		  repeat(BmpWidth)@(posedge clk);
		  #1 RGBEn = 0;
		end
		
	   repeat(10)@(posedge clk);
	 end
   endtask
	 
	 
	 
	 //����9x9��ֵ���ӵļ�����.��ͬ��initial���ǲ��е�.
    initial begin 
	   OutBmpFile1 = $fopen("output.bmp","w");                    //������浽������򿪵�bmp�ļ��У�����ļ��Ѵ�����ᱻ���ǡ�
		for(i2 = 1; i2 <= 54; i2 = i2 + 1) begin                   //��д��λͼ54�ֽڵ��ļ�ͷ�����ǰ�input.bmp���ļ�ͷ�����˹���
		  $fwrite(OutBmpFile1,"%c",BmpHeadMem[i2]);
		end
      
      repeat(4) @(posedge iBinaryOperator9x9.DataOutEn);         //9x9�����ӽ�����ԭ������ʱ4�У���Ϊ���ĵ����滹��4�У�����Ҫ����4�к��ٿ�ʼ����������ݣ�����ǰ���ImageSimInputҪ���������ʹ���ź�
		
      for(i2 = BmpHeight - 1; i2 >= 0; i2 = i2 - 1) begin        //����ж��initial��ʱ����ͬ�����ѭ������������ͬ
        @(posedge iBinaryOperator9x9.DataOutEn)
		  $fseek(OutBmpFile1, 54 + Stride * i2,0);                 //�Ѷ��ļ���λ�õ���ÿһ�����ݵĿ�ʼ
		  
        while(iBinaryOperator9x9.DataOutEn == 1) begin
        	@(posedge clk); 
        	InBetween = iBinaryOperator9x9.InBetween ? 8'hff : 8'h0;//�����ڣ�0��ǰ���ף�1 -> ff��  
        	$fwrite(OutBmpFile1,"%c%c%c",InBetween, InBetween, InBetween);  		
			if(BmpByteCount == 4)
			  $fwrite(OutBmpFile1, "%c", 8'hff);
        end     
			 
      end 
		
		$fclose(OutBmpFile1);  //ֻ�йر����ļ����ļ����ݲŻ�������д�뵽�ļ��С�
    end  
	 
  endmodule
