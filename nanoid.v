module nanoid

import math
import crypto.rand

// default_alphabet is the alphabet used for ID characters by default.
const default_alphabet = '_-0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ'.runes()

// get_mask generates bit mask used to obtain bits from the random bytes that are used to get index of random character
// from the alphabet. Example: if the alphabet has 6 = (110)_2 characters it is sufficient to use mask 7 = (111)_2
fn get_mask(alphabet_size int) int {
	for i in 1..9 {
		mask := (2 << u64(i)) - 1
		if mask >= alphabet_size - 1 {
			return mask
		}
	}
	return 0
}

// generate_opt is a low-level function to change alphabet and ID size.
pub fn generate_opt(alphabet string, size int) !string {
	chars := alphabet.runes()

	if alphabet.len == 0 || alphabet.len > 255 {
		return error('alphabet must not be empty and contain no more than 255 chars')
	}
	if size <= 0 {
		return error('size must be positive integer')
	}

	mask := get_mask(chars.len)
	// estimate how many random bytes we will need for the ID, we might actually need more but this is tradeoff
	// between average case and worst case
	ceil_arg := 1.6 * f64(mask * size) / f64(alphabet.len)
	step := int(math.ceil(ceil_arg))

	mut id := []rune{len: size}

	bytes := rand.read(step) or { return error(err.msg()) }

	mut j := 0
	for true {
		for i in 0..step {
			curr_byte := bytes[i] & u8(mask)
			if curr_byte < u8(chars.len) {
				id[j] = chars[curr_byte]
				j++
				if j == size {
					return id[..size].string()
				}
			}
		}
	}

	return error('could not generate')
}

// generate is the same as generate_opt but panics on error.
pub fn generate(alphabet string, size int) string {
	return generate_opt(alphabet, size) or { panic(err.msg()) }
}

// Allows the id size to be passed as a parameter
@[params]
pub struct NanoIDParams {
	size int = 21
}

// new_opt generates secure URL-friendly unique ID.
// Accepts optional parameter - length of the ID to be generated (21 by default).
pub fn new_opt(p NanoIDParams) !string {
	mut size := p.size
	if size <= 0 {
		return error('size must be positive integer')
	}

	bytes := rand.read(size)!

	mut id := []rune{len: size}
	for i in 0..size {
		id[i] = default_alphabet[bytes[i] & 63]
	}

	return id[..size].string()
}

// new is the same as new_opt but panics on error.
pub fn new(p NanoIDParams) string {
	return new_opt(p) or { panic(err.msg()) }
}
