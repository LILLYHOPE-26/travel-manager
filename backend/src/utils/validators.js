function requireFields(obj, fields) {
  return fields.filter((field) => {
    const value = obj?.[field];
    if (Array.isArray(value)) return value.length === 0;
    return value === undefined || value === null || value === '';
  });
}

module.exports = { requireFields };
