module SEDE (input clk,
			input rst,
			input [7:0] pix_data,
			output reg valid,
			output reg [7:0] edge_out,
			output reg busy
);
reg [7:0] current_state;
reg [7:0] next_state;
reg [7:0] count;    // colume index
reg [7:0] data_line_1 [31:0];
reg [7:0] data_line_2 [31:0];
reg [7:0] data_line_3 [31:0]; 
reg [7:0] count_row; // row index
reg signed [9:0] last_one_above;
reg signed [9:0] recent_one_above;
reg signed [9:0] next_one_above;
reg signed [9:0] last_one_middle;
reg signed [9:0] recent_one_middle;
reg signed [9:0] next_one_middle;
reg signed [9:0] last_one_below;
reg signed [9:0] recent_one_below;
reg signed [9:0] next_one_below;
reg signed [10:0] gradientX;
reg signed [10:0] gradientY;
reg signed [10:0] avg;
//State register
always@(posedge rst or posedge clk)begin
    if(rst) current_state <= 1;
    else  current_state <= next_state;
end
//Next state logic
always@(*)begin
    case(current_state)
        1 :  //first read into data_line_1
        begin
            if(count == 32)  next_state = 2;
            else next_state = 1;
        end
        2:  //first read into data_line_2
        begin 
            if(count == 31)  next_state = 3;
            else next_state = 2;
        end
        3:
        begin //first read into data_line_3
            if(count == 31)  next_state = 4;
            else next_state = 3;
        end
        4:
        begin   //first calculation
            if(count_row == 33) next_state = 6; 
            else if(count == 31) next_state = 5;
            else next_state = 4; 
        end
        5:
        begin   //read one row and data_line_2 -> data_line_1, datal_line_3 -> data_line_2, newdata stored in data_line_3
            if(count == 31)  next_state = 4;
            else next_state = 5;
        end
        default:
        begin
            if(count == 31) next_state = 1;
            else next_state = 6;
        end
    endcase
end
//data path and control path
always@(posedge rst or posedge clk)begin
    if(rst)
    begin
        count <= 0;
        busy <= 0;
        valid <= 0;
        count_row <= 0;
    end
    else
    begin
        case(current_state)
        1:  //Read first row, and output at the same time (since the result of first row will always be zero)
        begin
            data_line_1[count - 1] <= pix_data;
            if(count == 32)
            begin
                valid <= 0;
                count <= 0;
                count_row <= count_row + 1;
            end
            else
            begin
                valid <= 1;
                count <= count + 1;
                edge_out <= 0;
            end
        end
        2:  //Read second row 
        begin
            data_line_2[count] <= pix_data;
            if(count == 31)
            begin
                count_row <= count_row + 1;
                count <= 0;
            end
            else  count <= count + 1;
        end
        3:  //Read third row
        begin
            data_line_3[count] <= pix_data;
            if(count == 31)
            begin
                count_row <= count_row + 1;
                count <= 0;
                busy <= 1;
            end
            else  count <= count + 1;
        end
        4:  //first calculation and output the result of second row
        begin
            if(count == 31)
            begin
                busy <= 0;
                valid <= 0;
                count <= 0;
            end
            else if(count == 0 || count == 31)
            begin
                valid <= 1;
                count <= count + 1;
                edge_out <= 0;
                last_one_above <= $signed({1'b0,data_line_1[0]});
                recent_one_above <= $signed({1'b0,data_line_1[1]});
                next_one_above <= $signed({1'b0,data_line_1[2]});
                last_one_middle <= $signed({1'b0,data_line_2[0]});
                recent_one_middle <= $signed({1'b0,data_line_2[1]});
                next_one_middle <= $signed({1'b0,data_line_2[2]});
                last_one_below <= $signed({1'b0,data_line_3[0]});
                recent_one_below <= $signed({1'b0,data_line_3[1]});
                next_one_below <= $signed({1'b0,data_line_3[2]});
            end
            else 
            begin
                if(avg > 255) 
                begin
                    count <= count + 1;
                    edge_out <= 255;
                end
                else if (avg < 0)
                begin
                    count <= count + 1;
                    edge_out <= 0;
                end
                else
                begin
                    count <= count + 1;
                    edge_out <= avg;
                end
                    last_one_above <= $signed({1'b0,data_line_1[count]});
                    recent_one_above <= $signed({1'b0,data_line_1[count + 1]});
                    next_one_above <= $signed({1'b0,data_line_1[count + 2]});
                    last_one_middle <= $signed({1'b0,data_line_2[count]});
                    recent_one_middle <= $signed({1'b0,data_line_2[count + 1]});
                    next_one_middle <= $signed({1'b0,data_line_2[count + 2]});
                    last_one_below <= $signed({1'b0,data_line_3[count]});
                    recent_one_below <= $signed({1'b0,data_line_3[count + 1]});
                    next_one_below <= $signed({1'b0,data_line_3[count + 2]});
            end
        end
        5:
        begin
            data_line_1[count] <= data_line_2[count];
            data_line_2[count] <= data_line_3[count];
            data_line_3[count] <= pix_data;
            if(count == 31)
            begin
                edge_out <= 0;
                valid <= 1;
                busy <= 1;
                count_row <= count_row + 1;
                count <= 0; 
            end
            else count <= count + 1;
        end
        default:
        begin
            if(count == 31)
            begin
                count <= 0;
                valid <= 0;
            end
            else
            begin
                count <= count +  1;
                valid <= 1;
                edge_out <= 0;
            end
        end
        
        endcase
    end
end
always@(*)
begin
    gradientX = last_one_above - next_one_above + 2*last_one_middle - 2*next_one_middle + last_one_below - next_one_below;
    gradientY = last_one_above + 2*recent_one_above + next_one_above - last_one_below - 2*recent_one_below - next_one_below;
    avg = (gradientX + gradientY) / 2;
end
endmodule
