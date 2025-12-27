"use strict";

(async () => {
	// Create our memory interface. While we don't specify any specific memory
	// configuration, we'll use the interface to reference our exported Odin function.
	const memInterface = new odin.WasmMemoryInterface();
	await odin.runWasm("index.wasm", null, null, memInterface);
	// Now after the WASM module is loaded, we can access our exported functions.
	const exports = memInterface.exports;

	const input_field = document.getElementById("input");
	const output_field = document.getElementById("output");
	const version_select = document.getElementById("version_select")

	function update() {
		// allocate and store input
		const input = input_field.value
		const input_size = input.length
		memInterface.storeString(exports.alloc_input(input_size), input)

		// call wasm function
		const ptr = exports.calculate(version_select.value == "std140" ? 0 : 1)

		// get output
		const out_ptr = exports.get_output_ptr()
		const out_size = exports.get_output_size()
		const out = memInterface.loadString(out_ptr, out_size)
		output_field.value = out
	}

	input_field.addEventListener("input", update)
	version_select.addEventListener("change", update)
	update()
})();
