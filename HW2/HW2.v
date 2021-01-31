module HW2(
	clk_50M,
	reset_n,
	write,
	write_value,
	write_complete,
	read,
	read_value,
	read_complete,
	spi_csn,
	spi_sck,
	spi_do,
	spi_di
	);
	
input clk_50M;
input reset_n;
input write;
input [7:0]write_value;
 input read;
output write_complete;
 output read_value;
 output read_complete;
output spi_csn;
output spi_sck;
 output spi_do;
output spi_di;

reg write_complete=1'b1;
reg [7:0]read_value=8'b0;
reg read_complete=1'b0;
reg spi_csn=1'b1;
reg spi_sck=1'b0;
reg spi_do=1'b0;
reg spi_di=1'b0;

reg [31:0]counter_delay;
reg [31:0]counter_bits;
reg [31:0]counter_period;
reg [31:0]counter_data;
reg [1:0]state;
reg [1:0]next_state;
reg flag_next=1'b0;
wire neg_sck;
wire pos_sck;
reg data;
integer i;

parameter S0=0;
parameter S1=1;
parameter S2=2;

always@(posedge clk_50M or negedge reset_n)begin
	if(!reset_n)
		counter_delay<=32'd0;
	else begin
		if(counter_delay==32'd20)
			counter_delay<=32'd0;
		else
			counter_delay<=counter_delay+1;
	end
end

always@(posedge clk_50M or negedge reset_n)begin
	if(!reset_n)
		counter_period<=32'd0;
	else begin
		if(state==S1)
			if(counter_period==32'd25 || write==1)
				counter_period<=32'd0;
			else
				counter_period<=counter_period+1;
		else
			counter_period<=32'd0;
	end
end

always@(posedge clk_50M or negedge reset_n)begin
	if(!reset_n)
		counter_bits<=32'd0;
	else begin
		if(state==S1)begin
			if(counter_period==32'd20 && write==1'b0 && write_complete==0)begin
				if(counter_bits!=23)
					counter_bits<=counter_bits+1;
				else
					counter_bits<=0;
			end
			else
				counter_bits<=counter_bits;
		end
		else
			counter_bits<=32'd0;
	end
end

always@(posedge clk_50M or negedge reset_n)begin
	if(!reset_n)
		counter_data<=32'd0;
	else begin
		if(state==S1)
			if(counter_period==32'd20 && write==1'b0 && write_complete==0)begin
				if(counter_data==7)
					counter_data<=32'b0;
				else
					counter_data<=counter_data+1;
			end
			else
				counter_data<=counter_data;
		else
			counter_data<=32'd0;
	end
end

edge_detect edge1(
   .clk(clk_50M),
   .rst_n(reset_n),
   .data_in(spi_sck),
   .pos_edge(neg_sck),
   .neg_edge(pos_sck)	
);

always@(posedge clk_50M or negedge reset_n)begin
	if(!reset_n)
		write_complete<=1'b1;
	else begin
		if(write)
			write_complete<=1'b0;
		else if(counter_data==32'd7) begin
			if(counter_period==32'd20)
				write_complete<=1'b1;		
		end
	end		
end



always@(*)begin
	case(state)
		S0:begin
				next_state<=S1;
			end
		S1:begin
				next_state<=S0;
			end
		/*S2:begin
				next_state<=S0;
			end*/
		default:begin
						next_state<=S0;
					end
	endcase
end

always@(posedge clk_50M or negedge reset_n)begin
	if(!reset_n)
		state<=S0;
	else begin
		if(flag_next)
			state<=next_state;
		else
			state<=state;
	end
end

always@(posedge clk_50M or negedge reset_n)begin
	if(!reset_n)
		flag_next<=1'b0;
	else begin
		if(state==S0 && write==1'b1 )begin
			if(counter_delay==32'd19)
				flag_next<=1'b1;
			else
				flag_next<=1'b0;
		end
		else if(state==S1)begin
			if(write_value==8'h06)begin
				if(counter_bits==32'd7)begin
					if(counter_period==20)
						flag_next<=1'b1;
				end
				else
					flag_next<=1'b0;
			end
			else begin
				if(counter_bits==32'd23)begin
					if(counter_period==20)
						flag_next<=1'b1;
				end
				else
					flag_next<=1'b0;
			end
		end
		/*else begin
			if(counter_delay==32'd20)
				flag_next<=1'b1;
			else
				flag_next<=1'b0;
		end*/
	end
end

always@(posedge clk_50M or negedge reset_n)begin
	if(!reset_n)
		spi_csn<=1'b1;
	else begin
		if(state==S0 && write==1'b1)begin
			spi_csn<=1'b0;
		end
		else if(state==S1)begin
			if(counter_bits==32'd23)begin
				if(counter_period==20)
					spi_csn<=1'b1;
			end
			else
				spi_csn<=spi_csn;
		end
		else
			spi_csn<=1'b1;/////////////////////***///
	end
end	
always@(posedge clk_50M or negedge reset_n)begin	
	if(!reset_n)
		spi_sck<=1'b0;
	else begin
		if(state==S1)begin
			if((counter_period>32'd10 && write==1'b0 && spi_csn==1'b0 && counter_period<20) || write_complete==1)
				spi_sck<=1'b0;
			else if(counter_period<=32'd10 && write==1'b0 && spi_csn==1'b0 )
				spi_sck<=1'b1;
			else if(write==1'b1)
				spi_sck<=1'b0;
			else
				spi_sck<=1'b0;
		end
		else
			spi_sck<=1'b0;
	end
end


always@(posedge clk_50M or negedge reset_n)begin
	if(!reset_n)
		spi_di<=1'b0;
	else begin
		if(!write_complete)
			spi_do<=write_value[7-counter_data];
		else
			spi_do<=1'b0;
	end
end
	
endmodule
