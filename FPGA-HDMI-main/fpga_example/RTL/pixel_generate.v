//--------------------------------------------------------------------------------------------------------
// Module  : pixel_generate
// Type    : synthesizable
// Standard: Verilog 2001 (IEEE1364-2001)
// Function: Generate a digital clock display (HH:MM:SS) to test hdmi_tx_top.v
//--------------------------------------------------------------------------------------------------------

module pixel_generate # (
    parameter         RESP_LATENCY = 1         // 1, 2, or 3
) (
    input  wire       rstn,                   // Reset (active-low)
    input  wire       clk,                    // User clock (~27 MHz)
    input  wire       req_en,                 // Pixel request enable
    input  wire       req_sof,                // Start of frame
    input  wire       req_sol,                // Start of line
    output wire [7:0] resp_red,               // Pixel response: red
    output wire [7:0] resp_green,             // Pixel response: green
    output wire [7:0] resp_blue               // Pixel response: blue
);

    // Parameters for display
    localparam X_START = 160;                 // Start x-coordinate for clock (center: 640/2 - 160 = 160)
    localparam Y_START = 160;                 // Start y-coordinate for clock (center: 480/2 - 80 = 160)
    localparam DIGIT_WIDTH = 32;              // Width of each digit (32 pixels)
    localparam DIGIT_HEIGHT = 64;             // Height of each digit (64 pixels)
    localparam DIGIT_SPACING = 8;             // Spacing between digits/colon

    // Time counters
    reg [25:0] clk_counter = 0;               // Counter for 27 MHz clock to generate 1 Hz
    reg [5:0]  seconds = 0;                   // Seconds (0-59)
    reg [5:0]  minutes = 0;                   // Minutes (0-59)
    reg [4:0]  hours = 0;                     // Hours (0-23)
    reg [9:0]  x_pos = 0;                     // Current x-coordinate
    reg [9:0]  y_pos = 0;                     // Current y-coordinate

    // Pixel response registers
    reg [7:0]  resp1_red, resp1_green, resp1_blue;

    // Generate 1 Hz clock from 27 MHz
    localparam CLK_PER_SECOND = 27_000_000;   // 27 MHz
    always @(posedge clk or negedge rstn) begin
        if (~rstn) begin
            clk_counter <= 0;
            seconds <= 0;
            minutes <= 0;
            hours <= 0;
        end else begin
            if (clk_counter == CLK_PER_SECOND - 1) begin
                clk_counter <= 0;
                if (seconds == 59) begin
                    seconds <= 0;
                    if (minutes == 59) begin
                        minutes <= 0;
                        hours <= (hours == 23) ? 0 : hours + 1;
                    end else begin
                        minutes <= minutes + 1;
                    end
                end else begin
                    seconds <= seconds + 1;
                end
            end else begin
                clk_counter <= clk_counter + 1;
            end
        end
    end

    // Track pixel coordinates
    always @(posedge clk or negedge rstn) begin
        if (~rstn) begin
            x_pos <= 0;
            y_pos <= 0;
        end else if (req_en) begin
            if (req_sof) begin
                x_pos <= 0;
                y_pos <= 0;
            end else if (req_sol) begin
                x_pos <= 0;
                y_pos <= y_pos + 1;
            end else begin
                x_pos <= x_pos + 1;
            end
        end
    end

    // Font bitmap for digits 0-9 and colon (:)
    // Using 1D array to store 8x8 font for compatibility
    reg [7:0] font [0:87];  // 11 characters (0-9 + colon) x 8 rows
    initial begin
        // Digit 0
        font[0*8 + 0] = 8'b01111110;
        font[0*8 + 1] = 8'b10000001;
        font[0*8 + 2] = 8'b10000001;
        font[0*8 + 3] = 8'b10000001;
        font[0*8 + 4] = 8'b10000001;
        font[0*8 + 5] = 8'b10000001;
        font[0*8 + 6] = 8'b10000001;
        font[0*8 + 7] = 8'b01111110;
        // Digit 1
        font[1*8 + 0] = 8'b00011000;
        font[1*8 + 1] = 8'b00111000;
        font[1*8 + 2] = 8'b00011000;
        font[1*8 + 3] = 8'b00011000;
        font[1*8 + 4] = 8'b00011000;
        font[1*8 + 5] = 8'b00011000;
        font[1*8 + 6] = 8'b00011000;
        font[1*8 + 7] = 8'b00111110;
        // Digit 2
        font[2*8 + 0] = 8'b01111110;
        font[2*8 + 1] = 8'b10000001;
        font[2*8 + 2] = 8'b00000001;
        font[2*8 + 3] = 8'b00001110;
        font[2*8 + 4] = 8'b01110000;
        font[2*8 + 5] = 8'b10000000;
        font[2*8 + 6] = 8'b10000000;
        font[2*8 + 7] = 8'b11111111;
        // Digit 3
        font[3*8 + 0] = 8'b01111110;
        font[3*8 + 1] = 8'b10000001;
        font[3*8 + 2] = 8'b00000001;
        font[3*8 + 3] = 8'b00111110;
        font[3*8 + 4] = 8'b00000001;
        font[3*8 + 5] = 8'b00000001;
        font[3*8 + 6] = 8'b10000001;
        font[3*8 + 7] = 8'b01111110;
        // Digit 4
        font[4*8 + 0] = 8'b00001110;
        font[4*8 + 1] = 8'b00011100;
        font[4*8 + 2] = 8'b00111000;
        font[4*8 + 3] = 8'b01110000;
        font[4*8 + 4] = 8'b11111111;
        font[4*8 + 5] = 8'b00010000;
        font[4*8 + 6] = 8'b00010000;
        font[4*8 + 7] = 8'b00010000;
        // Digit 5
        font[5*8 + 0] = 8'b11111111;
        font[5*8 + 1] = 8'b10000000;
        font[5*8 + 2] = 8'b10000000;
        font[5*8 + 3] = 8'b11111110;
        font[5*8 + 4] = 8'b00000001;
        font[5*8 + 5] = 8'b00000001;
        font[5*8 + 6] = 8'b10000001;
        font[5*8 + 7] = 8'b01111110;
        // Digit 6
        font[6*8 + 0] = 8'b01111110;
        font[6*8 + 1] = 8'b10000001;
        font[6*8 + 2] = 8'b10000000;
        font[6*8 + 3] = 8'b11111110;
        font[6*8 + 4] = 8'b10000001;
        font[6*8 + 5] = 8'b10000001;
        font[6*8 + 6] = 8'b10000001;
        font[6*8 + 7] = 8'b01111110;
        // Digit 7
        font[7*8 + 0] = 8'b11111111;
        font[7*8 + 1] = 8'b00000001;
        font[7*8 + 2] = 8'b00000010;
        font[7*8 + 3] = 8'b00000100;
        font[7*8 + 4] = 8'b00001000;
        font[7*8 + 5] = 8'b00010000;
        font[7*8 + 6] = 8'b00100000;
        font[7*8 + 7] = 8'b01000000;
        // Digit 8
        font[8*8 + 0] = 8'b01111110;
        font[8*8 + 1] = 8'b10000001;
        font[8*8 + 2] = 8'b10000001;
        font[8*8 + 3] = 8'b01111110;
        font[8*8 + 4] = 8'b10000001;
        font[8*8 + 5] = 8'b10000001;
        font[8*8 + 6] = 8'b10000001;
        font[8*8 + 7] = 8'b01111110;
        // Digit 9
        font[9*8 + 0] = 8'b01111110;
        font[9*8 + 1] = 8'b10000001;
        font[9*8 + 2] = 8'b10000001;
        font[9*8 + 3] = 8'b01111111;
        font[9*8 + 4] = 8'b00000001;
        font[9*8 + 5] = 8'b00000001;
        font[9*8 + 6] = 8'b10000001;
        font[9*8 + 7] = 8'b01111110;
        // Colon (:)
        font[10*8 + 0] = 8'b00000000;
        font[10*8 + 1] = 8'b00011000;
        font[10*8 + 2] = 8'b00011000;
        font[10*8 + 3] = 8'b00000000;
        font[10*8 + 4] = 8'b00000000;
        font[10*8 + 5] = 8'b00011000;
        font[10*8 + 6] = 8'b00011000;
        font[10*8 + 7] = 8'b00000000;
    end

    // Calculate display regions for digits and colons
    // HH:MM:SS -> 8 characters (2 for hours, colon, 2 for minutes, colon, 2 for seconds)
    wire [9:0] x_end = X_START + 8 * (DIGIT_WIDTH + DIGIT_SPACING) - DIGIT_SPACING;  // Total width
    wire [9:0] y_end = Y_START + DIGIT_HEIGHT;                                       // Total height

    // Determine which character (digit or colon) to display
    reg [3:0] char_idx;  // 0-7: H1, H2, :, M1, M2, :, S1, S2
    reg [3:0] digit;     // Digit to display (0-9 or 10 for colon)
    always @(*) begin
        char_idx = 0;
        digit = 0;
        if (x_pos >= X_START && x_pos < X_START + DIGIT_WIDTH) begin
            char_idx = 0;  // Hours tens
            digit = hours / 10;
        end else if (x_pos >= X_START + DIGIT_WIDTH + DIGIT_SPACING && x_pos < X_START + 2*DIGIT_WIDTH + DIGIT_SPACING) begin
            char_idx = 1;  // Hours units
            digit = hours % 10;
        end else if (x_pos >= X_START + 2*(DIGIT_WIDTH + DIGIT_SPACING) && x_pos < X_START + 3*DIGIT_WIDTH + 2*DIGIT_SPACING) begin
            char_idx = 2;  // First colon
            digit = 10;
        end else if (x_pos >= X_START + 3*(DIGIT_WIDTH + DIGIT_SPACING) && x_pos < X_START + 4*DIGIT_WIDTH + 3*DIGIT_SPACING) begin
            char_idx = 3;  // Minutes tens
            digit = minutes / 10;
        end else if (x_pos >= X_START + 4*(DIGIT_WIDTH + DIGIT_SPACING) && x_pos < X_START + 5*DIGIT_WIDTH + 4*DIGIT_SPACING) begin
            char_idx = 4;  // Minutes units
            digit = minutes % 10;
        end else if (x_pos >= X_START + 5*(DIGIT_WIDTH + DIGIT_SPACING) && x_pos < X_START + 6*DIGIT_WIDTH + 5*DIGIT_SPACING) begin
            char_idx = 5;  // Second colon
            digit = 10;
        end else if (x_pos >= X_START + 6*(DIGIT_WIDTH + DIGIT_SPACING) && x_pos < X_START + 7*DIGIT_WIDTH + 6*DIGIT_SPACING) begin
            char_idx = 6;  // Seconds tens
            digit = seconds / 10;
        end else if (x_pos >= X_START + 7*(DIGIT_WIDTH + DIGIT_SPACING) && x_pos < X_START + 8*DIGIT_WIDTH + 7*DIGIT_SPACING) begin
            char_idx = 7;  // Seconds units
            digit = seconds % 10;
        end
    end

    // Scale 8x8 font to 32x64
    wire [9:0] x_local = x_pos - X_START - char_idx * (DIGIT_WIDTH + DIGIT_SPACING);  // Local x within digit
    wire [9:0] y_local = y_pos - Y_START;                                            // Local y within digit
    wire [2:0] font_x = x_local[4:2];  // Map 32 pixels to 8 (scale 4x)
    wire [2:0] font_y = y_local[5:3];  // Map 64 pixels to 8 (scale 8x)
    wire pixel_on = (x_pos >= X_START && x_pos < x_end && y_pos >= Y_START && y_pos < y_end) ?
                    font[digit*8 + font_y][7-font_x] : 1'b0;

    // Generate pixel data
    always @(posedge clk or negedge rstn) begin
        if (~rstn) begin
            resp1_red <= 0;
            resp1_green <= 0;
            resp1_blue <= 0;
        end else if (req_en) begin
            if (pixel_on) begin
                resp1_red <= 8'hFF;    // White for digit/colon
                resp1_green <= 8'hFF;
                resp1_blue <= 8'hFF;
            end else begin
                resp1_red <= 8'h00;    // Black background
                resp1_green <= 8'h00;
                resp1_blue <= 8'h00;
            end
        end
    end

    // Output pixel data based on RESP_LATENCY
    generate
        if (RESP_LATENCY <= 1) begin
            assign {resp_red, resp_green, resp_blue} = {resp1_red, resp1_green, resp1_blue};
        end else if (RESP_LATENCY == 2) begin
            reg [7:0] resp2_red, resp2_green, resp2_blue;
            always @(posedge clk) begin
                {resp2_red, resp2_green, resp2_blue} <= {resp1_red, resp1_green, resp1_blue};
            end
            assign {resp_red, resp_green, resp_blue} = {resp2_red, resp2_green, resp2_blue};
        end else begin
            reg [7:0] resp2_red, resp2_green, resp2_blue;
            reg [7:0] resp3_red, resp3_green, resp3_blue;
            always @(posedge clk) begin
                {resp2_red, resp2_green, resp2_blue} <= {resp1_red, resp1_green, resp1_blue};
                {resp3_red, resp3_green, resp3_blue} <= {resp2_red, resp2_green, resp2_blue};
            end
            assign {resp_red, resp_green, resp_blue} = {resp3_red, resp3_green, resp3_blue};
        end
    endgenerate

endmodule