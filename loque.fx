#include "ReShade.fxh"

#ifndef ENABLE_BORDER_XH
#define ENABLE_BORDER_XH 0
#endif

#ifndef ENABLE_CIRCLE_BORDER_XH
#define ENABLE_CIRCLE_BORDER_XH 0
#endif

#ifndef ENABLE_DOT_XH
#define ENABLE_DOT_XH 1
#endif

#ifndef ENABLE_CIRCLE_XH
#define ENABLE_CIRCLE_XH 1
#endif

#ifndef ENABLE_SQUARE_XH
#define ENABLE_SQUARE_XH 0
#endif

#ifndef ENABLE_CROSS_XH
#define ENABLE_CROSS_XH 0
#endif

#ifndef ENABLE_CROSS_UP_XH
#define ENABLE_CROSS_UP_XH 0
#endif

// #ifndef BORDER_THICKNESS_XH
#define BORDER_THICKNESS_XH 1.0
// #endif

#ifndef DOT_RADIUS_XH
#define DOT_RADIUS_XH 2
#endif

#ifndef CIRCLE_RADIUS_XH
#define CIRCLE_RADIUS_XH 32.5
#endif

#ifndef CIRCLE_THICKNESS_XH
#define CIRCLE_THICKNESS_XH 4
#endif

#ifndef SQUARE_LENGTH_XH
#define SQUARE_LENGTH_XH 1.5
#endif

#ifndef SQUARE_THICKNESS_XH
#define SQUARE_THICKNESS_XH 1.0
#endif

#ifndef CROSS_LENGTH_XH
#define CROSS_LENGTH_XH 9.5
#endif

#ifndef CROSS_THICKNESS_XH
#define CROSS_THICKNESS_XH 1.5
#endif

#ifndef CROSS_GAP_XH
#define CROSS_GAP_XH 5.5
#endif

#ifndef RED_CHANNEL_XH
#define RED_CHANNEL_XH 0.0
#endif

#ifndef BLUE_CHANNEL_XH
#define BLUE_CHANNEL_XH 0.0
#endif

#ifndef GREEN_CHANNEL_XH
#define GREEN_CHANNEL_XH 1.0
#endif

#ifndef ALPHA_CHANNEL_XH
#define ALPHA_CHANNEL_XH 1.0
#endif

#ifndef RED_BORDER_CHANNEL_XH
#define RED_BORDER_CHANNEL_XH 0.0
#endif

#ifndef BLUE_BORDER_CHANNEL_XH
#define BLUE_BORDER_CHANNEL_XH 0.0
#endif

#ifndef GREEN_BORDER_CHANNEL_XH
#define GREEN_BORDER_CHANNEL_XH 0.0
#endif

#ifndef ALPHA_BORDER_CHANNEL_XH
#define ALPHA_BORDER_CHANNEL_XH 1.0
#endif

#ifndef RED_CIRCLE_CHANNEL_XH
#define RED_CIRCLE_CHANNEL_XH 1.0
#endif

#ifndef BLUE_CIRCLE_CHANNEL_XH
#define BLUE_CIRCLE_CHANNEL_XH 1.0
#endif

#ifndef GREEN_CIRCLE_CHANNEL_XH
#define GREEN_CIRCLE_CHANNEL_XH 1.0
#endif

#ifndef ALPHA_CIRCLE_CHANNEL_XH
#define ALPHA_CIRCLE_CHANNEL_XH 0.125
#endif

#ifndef OFFSET_Y_XH
#define OFFSET_Y_XH 0
#endif

#ifndef OFFSET_X_XH
#define OFFSET_X_XH 0
#endif

#define SDF_WIDTH 128
#define SDF_HEIGHT 128

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
	
	MagFilter = POINT;
	MinFilter = POINT;
	MipFilter = POINT;

};

sampler2D bbsam
{
	Texture = ReShade::BackBufferTex;
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
	return abs(dot_distance(p, radius - (0.5 + (width * 0.5)))) - (0.5 + (width * 0.5));
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

float4 init_crosshair_texture(float4 vpos : SV_Position, float2 co : TexCoord) : SV_Target
{
	float4 colour = /*srgba_to_linear*/(float4(RED_CHANNEL_XH, GREEN_CHANNEL_XH, BLUE_CHANNEL_XH, ALPHA_CHANNEL_XH));
	float4 border = /*srgba_to_linear*/(float4(RED_BORDER_CHANNEL_XH, GREEN_BORDER_CHANNEL_XH, BLUE_BORDER_CHANNEL_XH, ALPHA_BORDER_CHANNEL_XH));
	float4 circle = /*srgba_to_linear*/(float4(RED_CIRCLE_CHANNEL_XH, GREEN_CIRCLE_CHANNEL_XH, BLUE_CIRCLE_CHANNEL_XH, ALPHA_CIRCLE_CHANNEL_XH));
	float2 offset = float2(0.5, 0.5);
	float2 centre = float2(SDF_WIDTH / 2.0, SDF_HEIGHT / 2.0);
	float4 cpx = float4(0.0, 0.0, 0.0, 0.0);
	float4 px = float4(0.0, 0.0, 0.0, 0.0);
	float d = 999;
	
	if(!!(ENABLE_CROSS_XH))//IF TRUE.
	{
		float hcross = box_distance(translate(vpos.xy + offset, centre), float2(CROSS_LENGTH_XH, CROSS_THICKNESS_XH), 0.0);
		d = merge(d, hcross);
		float vcross = box_distance(translate(vpos.xy + offset, centre), float2(CROSS_THICKNESS_XH, CROSS_LENGTH_XH), 0.0);
		d = merge(d, vcross);
		if(CROSS_GAP_XH > 0.0)
		{
			float subcross = box_distance(translate(vpos.xy + offset, centre), float2(CROSS_GAP_XH - 1.0, CROSS_GAP_XH - 1.0), 0.0);
			
			if(!(ENABLE_CROSS_UP_XH))
			{
				subcross = box_distance(translate(vpos.xy + offset, centre - float2(0.0, 1.0)), float2(CROSS_GAP_XH - 1.0, CROSS_GAP_XH), 0.0);
				float subcrossUp = box_distance(translate(vpos.xy + offset, centre - float2(0, CROSS_LENGTH_XH / 2 + CROSS_THICKNESS_XH)), float2(CROSS_THICKNESS_XH + 1.0, CROSS_LENGTH_XH / 2), 0.0);
				subcross = merge(subcross, subcrossUp);
			}
			d = subtract(subcross, d);
		}
		if(!(ENABLE_CROSS_UP_XH))
		{
			float subcross = box_distance(translate(vpos.xy + offset, centre - float2(0, CROSS_LENGTH_XH / 2 + CROSS_THICKNESS_XH)), float2(CROSS_THICKNESS_XH + 1.0, CROSS_LENGTH_XH / 2), 0.0);
			d = subtract(subcross, d);
		}
	}
	
	if(!!(ENABLE_DOT_XH))
	{
		float dot = dot_distance(translate(vpos.xy + offset, centre), DOT_RADIUS_XH + 0.5);
		d = merge(d, dot);
	}
	
	if(!!(ENABLE_SQUARE_XH))
	{
		float square1 = box_distance(translate(vpos.xy + offset, centre), float2(SQUARE_LENGTH_XH, SQUARE_LENGTH_XH), 0.0);
		float square2 = box_distance(translate(vpos.xy + offset, centre), float2(SQUARE_LENGTH_XH, SQUARE_LENGTH_XH) - float2(SQUARE_THICKNESS_XH * 2, SQUARE_THICKNESS_XH * 2), 0.0);
		d = merge(d, subtract(square2, square1));
	}
	
	if(!!(ENABLE_CIRCLE_XH))
	{
		if(
			ENABLE_CIRCLE_BORDER_XH == ENABLE_BORDER_XH &&
			circle.r == colour.r &&
			circle.g == colour.g &&
			circle.b == colour.b &&
			circle.a == colour.a
			)
		{
			float c = open_circle_distance(translate(vpos.xy + offset, centre), CIRCLE_RADIUS_XH, CIRCLE_THICKNESS_XH);
			d = merge(d, c);
		}
		else
		{
			if(!!(ENABLE_CIRCLE_BORDER_XH))
			{
				float cd = open_circle_distance(translate(vpos.xy + offset, centre), CIRCLE_RADIUS_XH, CIRCLE_THICKNESS_XH);
				float4 bpx = border;
				bpx.a *= border_mask(cd, BORDER_THICKNESS_XH);
				cpx = lerp(bpx, circle, fill_mask(cd));
			}
			else
			{
				cpx = circle;
				cpx.a *= fill_mask(open_circle_distance(translate(vpos.xy + offset, centre), CIRCLE_RADIUS_XH, CIRCLE_THICKNESS_XH));
			}
		}
	}
	
	if(!!(ENABLE_BORDER_XH))
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
	
	if(!!(ENABLE_CIRCLE_XH))
	{
		if(cpx.a > 0.0)
		{
			px = cpx;
		}
	}
	
	return px;
}

float4 draw_crosshair(float4 vpos : SV_Position, float2 co : TexCoord) : SV_Target
{
	const float2 xhpos = float2(BUFFER_WIDTH / 2 - (SDF_WIDTH / 2) + OFFSET_X_XH, BUFFER_HEIGHT / 2 - (SDF_HEIGHT / 2) + OFFSET_Y_XH);
	if((vpos.x >= xhpos.x) && (vpos.x < xhpos.x + SDF_WIDTH) && (vpos.y >= xhpos.y) && (vpos.y < xhpos.y + SDF_HEIGHT))
	{
		float4 bb = tex2D(bbsam, co);
		float4 xh = tex2D(xhsam, (vpos.xy - xhpos) / SDF_WIDTH);
		if(xh.r < 0)
		{
			return lerp(bb, float4(1.0, 1.0, 1.0, 1.0) - bb, xh.a);
		}
		return lerp(bb, xh, xh.a);
	}
	return tex2D(bbsam, co);
}

technique SDFCrosshair
< enabled = true; timeout = 1; hidden = true; >
{
	pass
	{
		ClearRenderTargets = true;
		VertexShader = PostProcessVS;
		PixelShader = init_crosshair_texture;
		RenderTarget0 = xhtex;
	}
}

technique Crosshair
< ui_tooltip = "Crosshair inspired by signed distance fields.\n\nhttps://github.com/Fragonite/loque"; >
{
    pass
    {
    	// SRGBWriteEnable = true;
        VertexShader = PostProcessVS;
        PixelShader = draw_crosshair;
    }
}