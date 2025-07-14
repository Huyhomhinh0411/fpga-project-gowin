module hdmi_counter (
    input wire clk,          // Clock 100 MHz
    input wire reset,        // Reset tín hiệu
    output wire [2:0] tmds   // 3 kênh TMDS cho HDMI (Red, Green, Blue)
);

reg [26:0] count;
reg [5:0] hour, minute, second;
reg [9:0] hcount, vcount; // Đếm ngang và dọc cho tín hiệu video
reg hsync, vsync, video_active;
wire [7:0] red, green, blue;

// Bộ đếm thời gian
always @(posedge clk or posedge reset) begin
    if (reset) begin
        count <= 0;
        hour <= 0;
        minute <= 0;
        second <= 0;
    end else begin
        if (count == 100000000) begin // 1 giây với clock 100 MHz
            count <= 0;
            if (second == 59) begin
                second <= 0;
                if (minute == 59) begin
                    minute <= 0;
                    if (hour == 23) begin
                        hour <= 0;
                    end else begin
                        hour <= hour + 1;
                    end
                end else begin
                    minute <= minute + 1;
                end
            end else begin
                second <= second + 1;
            end
        end else begin
            count <= count + 1;
        end
    end
end

// Tạo tín hiệu video 640x480 @ 60Hz
localparam H_ACTIVE = 640;
localparam H_FRONT_PORCH = 16;
localparam H_SYNC = 96;
localparam H_BACK_PORCH = 48;
localparam V_ACTIVE = 480;
localparam V_FRONT_PORCH = 10;
localparam V_SYNC = 2;
localparam V_BACK_PORCH = 33;

always @(posedge clk or posedge reset) begin
    if (reset) begin
        hcount <= 0;
        vcount <= 0;
        hsync <= 0;
        vsync <= 0;
        video_active <= 0;
    end else begin
        if (hcount == (H_ACTIVE + H_FRONT_PORCH + H_SYNC + H_BACK_PORCH - 1)) begin
            hcount <= 0;
            if (vcount == (V_ACTIVE + V_FRONT_PORCH + V_SYNC + V_BACK_PORCH - 1)) begin
                vcount <= 0;
            end else begin
                vcount <= vcount + 1;
            end
        end else begin
            hcount <= hcount + 1;
        end

        // Tín hiệu đồng bộ
        hsync <= (hcount >= (H_ACTIVE + H_FRONT_PORCH) && hcount < (H_ACTIVE + H_FRONT_PORCH + H_SYNC));
        vsync <= (vcount >= (V_ACTIVE + V_FRONT_PORCH) && vcount < (V_ACTIVE + V_FRONT_PORCH + V_SYNC));
        video_active <= (hcount < H_ACTIVE && vcount < V_ACTIVE);
    end
end

// Hiển thị thời gian đơn giản (ví dụ: màu trắng khi trong vùng active)
assign red   = (video_active && (hcount / 80 == hour[5:0] % 8 || vcount / 60 == second[5:0] % 8)) ? 8'hFF : 8'h00;
assign green = (video_active && (hcount / 80 == minute[5:0] % 8)) ? 8'hFF : 8'h00;
assign blue  = 8'h00;

// Mô-đun TMDS đơn giản (cần IP core thực tế cho HDMI)
tmds_encoder tmds_r (.clk(clk), .reset(reset), .data_in(red),   .tmds_out(tmds[2]));
tmds_encoder tmds_g (.clk(clk), .reset(reset), .data_in(green), .tmds_out(tmds[1]));
tmds_encoder tmds_b (.clk(clk), .reset(reset), .data_in(blue),  .tmds_out(tmds[0]));

endmodule

module tmds_encoder (
    input wire clk,
    input wire reset,
    input wire [7:0] data_in,
    output reg tmds_out
);
    // TMDS encoding đơn giản (thay bằng IP core thực tế)
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            tmds_out <= 0;
        end else begin
            tmds_out <= data_in[0]; // Ví dụ cơ bản, cần TMDS encoder đầy đủ
        end
    end
endmodule