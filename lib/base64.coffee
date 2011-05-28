###
Base64 utils

Only encoding for now.

(C) Emiel Mols, 2010. Released under the Simplified BSD License.
    Attribution is very much appreciated.
###
class Base64
	
	code = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/='

	@encode: (array) ->
		output = ''
		for i in [0...Math.ceil(array.length/3)*3] by 3
			a0 = array[i]||0x00
			a1 = array[i+1]||0x00
			a2 = array[i+2]||0x00
		
			output += code.charAt((a0 >> 2) & 0x3f) +
				code.charAt(((a1 >> 4) | (a0 << 4)) & 0x3f) +
				( if i+1 >= array.length then '=' else code.charAt(((a2 >> 6) | (a1 << 2)) & 0x3f) ) +
				( if i+2 >= array.length then '=' else code.charAt(a2 & 0x3f) )
				
		return output
