texture BackBufferTex : COLOR;

uniform bool ENABLE_DOT_XH
<
	ui_label = "Enable Dot";
	ui_spacing = 8;
> = true;

uniform float DOT_RADIUS_XH
<
	ui_type = "drag";
	ui_min = 0.0;
	ui_max = 60.0;
	ui_label = "Radius";
	ui_step = 1.0;
> = 2.0;

uniform bool ENABLE_CIRCLE_XH
<
	ui_label = "Enable Circle";
	ui_spacing = 8;
> = true;

uniform float CIRCLE_RADIUS_XH
<
	ui_label = "Radius";
	ui_type = "drag";
	ui_min = 0.0;
	ui_max = 60.0;
	ui_step = 1.0;
> = 32.0;

uniform float CIRCLE_THICKNESS_XH
<
	ui_label = "Thiccness";
	ui_type = "drag";
	ui_min = 0.0;
	ui_max = 60.0;
	ui_step = 1.0;
> = 4.0;

uniform float4 CIRCLE_COLOUR_XH
<
	ui_label = "Colour";
	ui_type = "color";
> = float4(1.0, 1.0, 1.0, 0.125);

uniform uint CIRCLE_BLENDING_XH
<
	ui_label = " ";
	ui_type = "radio";
	ui_items = "Linear\0Additive/Mixed\0Inversion\0";
> = 1;

uniform bool ENABLE_CROSS_XH
<
	ui_label = "Enable Cross";
	ui_spacing = 8;
> = false;

uniform bool ENABLE_CROSS_UP_XH
<
	ui_label = "Enable Top Section";
> = false;

uniform float CROSS_LENGTH_XH
<
	ui_label = "Length";
	ui_type = "drag";
	ui_min = 0.0;
	ui_max = 120.0;
	ui_step = 1.0;
> = 18.0;

uniform float CROSS_THICKNESS_XH
<
	ui_label = "Thiccness";
	ui_type = "drag";
	ui_min = 0.0;
	ui_max = 120.0;
	ui_step = 1.0;
> = 2.0;

uniform float CROSS_GAP_XH
<
	ui_label = "Gap";
	ui_type = "drag";
	ui_min = 0.0;
	ui_max = 120.0;
	ui_step = 1.0;
> = 10.0;

uniform bool ENABLE_SQUARE_XH
<
	ui_label = "Enable Square";
	ui_spacing = 8;
> = false;

uniform float SQUARE_LENGTH_XH
<
	ui_label = "Length";
	ui_type = "drag";
	ui_min = 0.0;
	ui_max = 120.0;
	ui_step = 1.0;
> = 2.0;

uniform float SQUARE_THICKNESS_XH
<
	ui_label = "Thiccness";
	ui_type = "drag";
	ui_min = 0.0;
	ui_max = 60.0;
	ui_step = 1.0;
> = 1.0;

uniform float4 FILL_COLOUR_XH
<
	ui_label = "Colour";
	ui_type = "color";
	ui_spacing = 8;
> = float4(0.0, 1.0, 0.0, 1.0);

uniform int BLENDING_XH
<
	ui_label = " ";
	ui_type = "radio";
	ui_items = "Linear\0Additive/Mixed\0Inversion\0";
>;

uniform float4 BORDER_COLOUR_XH
<
	ui_label = "Border";
	ui_type = "color";
	ui_spacing = 8;
> = float4(0.0, 0.0, 0.0, 1.0);

uniform bool ENABLE_BORDER_XH
<
	ui_label = "Enable Border";
> = false;

uniform bool ENABLE_CIRCLE_BORDER_XH
<
	ui_label = "Enable Circle Border";
> = false;


// #ifndef BORDER_THICKNESS_XH
#define BORDER_THICKNESS_XH 999.0
// #endif

uniform float OFFSET_X_XH
<
	ui_label = "X Offset";
	ui_type = "drag";
	ui_step = 1.0;
> = 0.0;

uniform float OFFSET_Y_XH
<
	ui_label = "Y Offset";
	ui_type = "drag";
	ui_step = 1.0;
> = 0.0;

#define SDF_WIDTH 128.0
#define SDF_HEIGHT 128.0

texture2D xhtex
{
	Width = SDF_WIDTH;
	Height = SDF_HEIGHT;
	Format = RGBA32F;
};

sampler2D xhsam
{
	Texture = xhtex;
	// AddressU = CLAMP;
	// AddressV = CLAMP;
	
	// MagFilter = POINT;
	// MinFilter = POINT;
	// MipFilter = POINT;

};

sampler2D bbsam
{
	Texture = BackBufferTex;
	// AddressU = CLAMP;
	// AddressV = CLAMP;
	// SRGBTexture = true;
	
	// MagFilter = POINT;
	// MinFilter = POINT;
	// MipFilter = POINT;

};

float srgb_to_linear(float c)
{
	if(c <= 0.04045)
	{
		return c / 12.92;
	}
	return pow(((c + 0.055) / 1.055), 2.4);
}

float4 srgba_to_linear(float4 c)
{
	c.r = srgb_to_linear(c.r);
	c.g = srgb_to_linear(c.g);
	c.b = srgb_to_linear(c.b);
	return c;
}

float merge(float d1, float d2)
{
	return min(d1, d2);
}

float subtract(float d1, float d2)
{
	return max(-d1, d2);
}

float fill_mask(float d)
{
	return clamp(-d, 0.0, 1.0);
}

float border_mask(float d, float width)
{
	//dist += 1.0;
	float alpha1 = clamp(d + width, 0.0, 1.0);
	float alpha2 = clamp(d, 0.0, 1.0);
	return alpha1 - alpha2;
}

float dot_distance(float2 p, float radius)
{
	return length(p) - radius;
}

float open_circle_distance(float2 p, float radius, float width)
{
	// return abs(dot_distance(p, radius - (0.5 + (width * 0.5)))) - (0.5 + (width * 0.5));
	float c1 = length(p) - (radius + 0.5);
	float c2 = length(p) - ((radius + 0.5) - (width + 1.0));
	return subtract(c2, c1);
}

float box_distance(float2 p, float2 size, float radius)
{
	size -= float2(radius, radius);
	float2 d = abs(p) - size;
	return min(max(d.x, d.y), 0) + length(max(d, 0)) - radius;
}

float2 translate(float2 p, float2 t)
{
	return p - t;
}

float4 ps_init_crosshair_texture(float4 vpos : SV_Position, float2 co : TexCoord) : SV_Target
{
	float4 colour = FILL_COLOUR_XH;//srgba_to_linear(FILL_COLOUR_XH);
	float4 border = BORDER_COLOUR_XH;//srgba_to_linear(BORDER_COLOUR_XH);
	float4 circle = CIRCLE_COLOUR_XH;//srgba_to_linear(CIRCLE_COLOUR_XH);
	float2 offset = float2(0.5, 0.5);
	float2 centre = float2(SDF_WIDTH / 2.0, SDF_HEIGHT / 2.0);
	float4 cpx = float4(0.0, 0.0, 0.0, 0.0);
	float4 px = float4(0.0, 0.0, 0.0, 0.0);
	float d = 999;
	
	float xl = CROSS_LENGTH_XH / 2 + 0.5;
	float xt = CROSS_THICKNESS_XH / 2 + 0.5;
	float xg = CROSS_GAP_XH / 2 - 0.5;
	
	if(ENABLE_CROSS_XH)
	{
		float hcross = box_distance(translate(vpos.xy + offset, centre), float2(xl, xt), 0.0);
		d = merge(d, hcross);
		float vcross = box_distance(translate(vpos.xy + offset, centre), float2(xt, xl), 0.0);
		d = merge(d, vcross);
		if(CROSS_GAP_XH > 0.0)
		{
			float subcross = (ENABLE_CROSS_UP_XH) ? 
			box_distance(translate(vpos.xy + offset, centre), float2(xg, xg), 0.0) :
			box_distance(translate(vpos.xy + offset, centre - float2(0.0, xt)), float2(xg, xg + xt), 0.0);
			
			d = subtract(subcross, d);
		}
		if(!(ENABLE_CROSS_UP_XH))
		{
			float subcross = box_distance(translate(vpos.xy + offset, centre - float2(0, xl + xt)), float2(xt + 2.0, xl), 0.0);
			d = subtract(subcross, d);
		}
	}
	
	if(ENABLE_DOT_XH)
	{
		float dot = dot_distance(translate(vpos.xy + offset, centre), DOT_RADIUS_XH + 0.5);
		d = merge(d, dot);
	}
	
	if(ENABLE_SQUARE_XH)
	{
		float sl = SQUARE_LENGTH_XH / 2.0 + 0.5;
		float square1 = box_distance(translate(vpos.xy + offset, centre), float2(sl, sl), 0.0);
		float square2 = box_distance(translate(vpos.xy + offset, centre), float2(sl, sl) - float2(SQUARE_THICKNESS_XH + 1.0, SQUARE_THICKNESS_XH + 1.0), 0.0);
		d = merge(d, subtract(square2, square1));
	}
	
	if(ENABLE_CIRCLE_XH)
	{
		float cd = open_circle_distance(translate(vpos.xy + offset, centre), CIRCLE_RADIUS_XH, CIRCLE_THICKNESS_XH);
		if(
			ENABLE_CIRCLE_BORDER_XH == ENABLE_BORDER_XH &&
			circle.r == colour.r &&
			circle.g == colour.g &&
			circle.b == colour.b &&
			circle.a == colour.a
			)
		{
			d = merge(d, cd);
		}
		else
		{
			if(ENABLE_CIRCLE_BORDER_XH)
			{
				float4 bpx = border;
				bpx.a *= border_mask(cd, BORDER_THICKNESS_XH);
				cpx = lerp(bpx, circle, fill_mask(cd));
			}
			else
			{
				cpx = circle;
				cpx.a *= fill_mask(cd);
			}
			cpx.a = -cpx.a;
		}
	}
	
	if(ENABLE_BORDER_XH)
	{
		float4 bpx = border;
		bpx.a *= border_mask(d, BORDER_THICKNESS_XH);
		px = lerp(bpx, colour, fill_mask(d));
	}
	else
	{
		px = colour;
		px.a *= fill_mask(d);
	}
	
	if(ENABLE_CIRCLE_XH)
	{
		if(cpx.a < 0.0)
		{
			px = cpx;
		}
	}
	
	return px;
}

float4 ps_draw_crosshair(float4 vpos : SV_Position, float2 co : TexCoord, float2 bbCoord : TEXCOORD1) : SV_Target
{
	float4 xh = tex2D(xhsam, co);
	float4 bb = tex2D(bbsam, bbCoord);
	
	if(xh.a < 0)
	{
		switch(CIRCLE_BLENDING_XH)
		{
			case 0:
			return lerp(bb, xh, -xh.a);
			
			case 1:
			return lerp(bb, frac(bb) + xh, -xh.a);
			
			default://case 2:
			return lerp(bb, float4(1.0, 1.0, 1.0, 1.0) - bb, -xh.a);
		}
	}
	
	switch(BLENDING_XH)
	{
		case 0:
		return lerp(bb, xh, xh.a);
		
		case 1:
		return lerp(bb, frac(bb) + xh, xh.a);
		
		default://case 2:
		return lerp(bb, float4(1.0, 1.0, 1.0, 1.0) - bb, xh.a);
	}
}

float4 vs_quad_draw( uint vid : SV_VERTEXID, out float2 uv : TEXCOORD, out float2 bbCoord : TEXCOORD1) : SV_POSITION
{
	uv.y = vid % 2, uv.x = vid / 2;
	float4 pos = float2((uv.x*2-1) * SDF_WIDTH, (1.-uv.y*2) * SDF_HEIGHT).xyxy;
	pos.x *= BUFFER_RCP_WIDTH, pos.y *= BUFFER_RCP_HEIGHT;
	pos = float4(pos.xy + float2(OFFSET_X_XH / (BUFFER_WIDTH / 2), OFFSET_Y_XH / (BUFFER_HEIGHT / 2)), 0, 1);
	bbCoord = ((pos.xy * 0.5) + 0.5);
	bbCoord.y = 1 - bbCoord.y;
	return pos;
}

float4 vs_quad_texture( uint vid : SV_VERTEXID, out float2 uv : TEXCOORD) : SV_POSITION
{
	uv.y = vid % 2, uv.x = vid / 2;
	float2 pos = float2((uv.x*2-1) * BUFFER_WIDTH, (1.-uv.y*2) * BUFFER_HEIGHT);
	return pos.x *= BUFFER_RCP_WIDTH, pos.y *= BUFFER_RCP_HEIGHT, float4(pos, 0, 1);
}

technique SDFCrosshair
< enabled = true; timeout = 1; hidden = true; >
{
	pass
	{
		PrimitiveTopology = TRIANGLESTRIP;
		VertexCount = 4;
		
		ClearRenderTargets = true;
		RenderTarget0 = xhtex;
		
		VertexShader = vs_quad_texture;
		PixelShader = ps_init_crosshair_texture;
	}
}

technique Crosshair
< ui_tooltip = "Crosshair inspired by signed distance fields.\n\nhttps://github.com/Fragonite/loque"; >
{
    pass
    {
    	// SRGBWriteEnable = true;
    	PrimitiveTopology = TRIANGLESTRIP;
    	VertexCount = 4;
    	
    	// BlendEnable = true;
    	// SrcBlend = SRCALPHA;
    	// DestBlend = INVSRCALPHA;
    	
    	VertexShader = vs_quad_draw;//PostProcessVS;
    	PixelShader = ps_draw_crosshair;
    }
}