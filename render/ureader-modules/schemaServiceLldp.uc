function moduleServiceLldp(location, value, errors) {
	if (type(value) == "object") {
		let obj = {};

		function parseSystemName(location, value, errors) {
			if (type(value) != "string")
				push(errors, [ location, "must be of type string" ]);

			return value;
		}

		if (exists(value, "system-name")) {
			obj.system_name = parseSystemName(location + "/system-name", value["system-name"], errors);
		}

		function parseSystemDescription(location, value, errors) {
			if (type(value) != "string")
				push(errors, [ location, "must be of type string" ]);

			return value;
		}

		if (exists(value, "system-description")) {
			obj.system_description = parseSystemDescription(location + "/system-description", value["system-description"], errors);
		}

		return obj;
	}

	if (type(value) != "object")
		push(errors, [ location, "must be of type object" ]);

	return value;
}

return {
	validate: function(location, value, errors) {
		return moduleServiceLldp(location, value, errors);
	}
};
