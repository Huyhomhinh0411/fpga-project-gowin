module bai3 (
    input wire clk,      
    input wire rst,        
    input wire button,     
    output reg led1,        
    output reg led2         
);

// chia tan so
reg [23:0] counter;
always @(posedge clk or negedge rst) begin
    if (!rst) begin
        counter <= 0;
        led1 <= 0;
    end else begin
        counter <= counter + 1;
        if (counter == 24'd100_000_000) begin
            led1 <= ~led1;    
            counter <= 0;
        end
    end
end

always @(posedge clk or negedge rst) begin
    if (!rst) begin
        led2 <= 0;
    end else begin
        if (button) begin
            led2 <= 1'b0;    
        end
		else begin
		led2 <= 1'b1;
		end
    end
end

endmodule