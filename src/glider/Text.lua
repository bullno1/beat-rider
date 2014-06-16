local Asset = require "glider.Asset"

return component(..., function(i)
	depends "glider.Renderable"

	property("FontName",
		function(self, ent)
			return self.fontName
		end,
		function(self, ent, val)
			self.fontName = val
			self.style:setFont(Asset.get("font:"..val))
		end
	)

	property("FontSize",
		function(self, ent)
			return self.style:getSize()
		end,
		function(self, ent, val)
			self.style:setSize(val)
		end
	)

	property("TextRect",
		function(self, ent)
			return {ent:getTransform():getRect()}
		end,
		function(self, ent, val)
			ent:getTransform():setRect(unpack(val))
		end
	)
	
	local ALIGNMENT_MAP = {
		left = MOAITextBox.LEFT_JUSTIFY,
		center = MOAITextBox.CENTER_JUSTIFY,
		right = MOAITextBox.RIGHT_JUSTIFY,
		top = MOAITextBox.LEFT_JUSTIFY,
		bottom = MOAITextBox.RIGHT_JUSTIFY
	}
	property("TextAlignment",
		function(self, ent)
			return self.alignment
		end,
		function(self, ent, val)
			self.alignment = val
			local hAlignment, vAlignment = unpack(val)
			ent:getTransform():setAlignment(
				ALIGNMENT_MAP[hAlignment],
				ALIGNMENT_MAP[vAlignment]
			)
		end
	)

	property("Text",
		function(self, ent)
			return self.text
		end,
		function(self, ent, val)
			self.text = val
			ent:getTransform():setString(val)
		end
	)

	msg("onCreate", function(self, ent)
		local prop = ent:_requestTransformType("MOAITextBox")
		local style = MOAITextStyle.new()
		prop:setStyle(style)
		prop:setYFlip(true)

		self.style = style
		prop.entity = ent
	end)
end)
