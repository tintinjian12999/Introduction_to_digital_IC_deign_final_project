
`define DATA_NUM 1024
`define CYCLE 10
`define PATTERN "file.txt"
`define EXPECT "golden.txt"
`timescale 1ns/100ps

module testfixture ;

reg [7:0] pix_data ; 
reg clk,rst ;
wire [7:0]edge_out ;
wire valid ;
wire busy;
reg [15:0] out_cnt,in_cnt,in_cnt_d1;
reg [7:0]pattern_in[0:`DATA_NUM-1] ;
reg [7:0]ans[0:`DATA_NUM-1] ;
wire [7:0]edge_exp ;
reg [7:0] edge_reg;
 
SEDE u_SEDE(.clk(clk),
			.rst(rst),
			.valid(valid),
			.pix_data(pix_data),
			.edge_out(edge_out),
			.busy(busy)
);

always begin #(`CYCLE/2) clk=~clk ; end  //clock generator

initial begin
$readmemb(`PATTERN,pattern_in) ;
$readmemb(`EXPECT,ans) ;
end

integer i ,err ,check;

initial begin
	clk=1'b0 ;
	err=0 ;
	check=0;
	@(negedge clk) rst=1'b1 ;
	#(`CYCLE*1.75) rst=1'b0 ;
end

always@(posedge clk or posedge rst)
	if(rst)
		in_cnt <= 0;
	else if(~busy)
		in_cnt <= in_cnt + 1;

always@(posedge clk)
	if(~busy)
		in_cnt_d1 <= in_cnt;

always@(posedge clk or posedge rst)
	if(rst)
		pix_data <= 8'bz;
	else if(~busy)
		pix_data <= pattern_in[in_cnt];
	else if(busy)
		pix_data <= pattern_in[in_cnt_d1];

assign edge_exp = ans[out_cnt] ;

always@(posedge clk)begin
	if(valid)begin
		if(edge_out!=edge_exp) begin
			err <= err+1 ;
			$display($time,"Error  output:%d, edge_out=%h",out_cnt,edge_out) ;
			$display($time,"Expect output:%d, edge_out=%h",out_cnt,edge_exp) ;
		end
		else if(edge_out==edge_exp) check <= check+1;
    end
end

always@(posedge clk or posedge rst)
	if(rst)
		out_cnt <= 0;
	else if(valid)
		out_cnt <= out_cnt + 1;
		
always@(posedge clk)
		edge_reg <= edge_out;

always@(posedge clk)begin
	if(out_cnt == 1024)begin
		#(`CYCLE)
		if((err==0)&&(check==1024)) begin
			$display("-------------------   SEDE check successfully   -------------------");
			$display("            $$              ");
			$display("           $  $");
			$display("           $  $");
			$display("          $   $");
			$display("         $    $");
			$display("$$$$$$$$$     $$$$$$$$");
			$display("$$$$$$$              $");
			$display("$$$$$$$              $");
			$display("$$$$$$$              $");
			$display("$$$$$$$              $");
			$display("$$$$$$$              $");
			$display("$$$$$$$$$$$$         $$");
			$display("$$$$$      $$$$$$$$$$");
			$finish ;
		end
		else if((err==0)&&(check!=1024)) begin
			$display("-----------   Oops! Something wrong with your code!   ------------");
			$finish ;
		end
		else 
			$display("-------------------   There are %d errors   -------------------", err);
		$finish ;
	end
end

initial begin
	#(`CYCLE*100000)
	$display("-----------   Oops! There is something wrong with your code! It can't stop.   ------------");
	$display("-------------------   There are 1024 errors   -------------------" );
	$finish ;
end

endmodule


