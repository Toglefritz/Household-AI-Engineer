"use strict";
/**
 * Parameter validation system for testing Kiro commands safely.
 *
 * This module provides comprehensive parameter validation capabilities
 * to ensure safe command testing and accurate parameter discovery.
 */
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || function (mod) {
    if (mod && mod.__esModule) return mod;
    var result = {};
    if (mod != null) for (var k in mod) if (k !== "default" && Object.prototype.hasOwnProperty.call(mod, k)) __createBinding(result, mod, k);
    __setModuleDefault(result, mod);
    return result;
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.ParameterValidator = void 0;
const vscode = __importStar(require("vscode"));
/**
 * Validates command parameters with comprehensive type checking and rules.
 *
 * The ParameterValidator provides safe parameter validation for command testing,
 * ensuring that parameters meet expected types and constraints before execution.
 */
class ParameterValidator {
    /**
     * Validates a set of parameters against their definitions.
     *
     * @param parameters Parameter definitions to validate against
     * @param values Parameter values to validate
     * @param context Validation context
     * @returns Promise that resolves to validation results
     */
    async validateParameters(parameters, values, context) {
        const errors = [];
        const warnings = [];
        const validatedValues = {};
        console.log(`ParameterValidator: Validating ${parameters.length} parameters for ${context.commandId}`);
        // Validate each parameter
        for (const parameter of parameters) {
            const value = values[parameter.name];
            const paramResult = await this.validateParameter(parameter, value, context);
            if (!paramResult.valid) {
                errors.push(...paramResult.errors);
            }
            warnings.push(...paramResult.warnings);
            if (paramResult.value !== undefined) {
                validatedValues[parameter.name] = paramResult.value;
            }
        }
        // Check for unexpected parameters
        for (const [key, value] of Object.entries(values)) {
            if (!parameters.find(p => p.name === key)) {
                warnings.push({
                    parameterName: key,
                    message: `Unexpected parameter '${key}' not defined in command signature`,
                    code: 'UNEXPECTED_PARAMETER'
                });
            }
        }
        const result = {
            valid: errors.length === 0,
            errors,
            warnings,
            value: validatedValues
        };
        console.log(`ParameterValidator: Validation ${result.valid ? 'passed' : 'failed'} with ${errors.length} errors, ${warnings.length} warnings`);
        return result;
    }
    /**
     * Validates a single parameter value.
     *
     * @param parameter Parameter definition
     * @param value Value to validate
     * @param context Validation context
     * @returns Promise that resolves to validation result
     */
    async validateParameter(parameter, value, context) {
        const errors = [];
        const warnings = [];
        let validatedValue = value;
        // Check if required parameter is missing
        if (parameter.required && (value === undefined || value === null)) {
            errors.push({
                parameterName: parameter.name,
                message: `Required parameter '${parameter.name}' is missing`,
                code: 'REQUIRED_PARAMETER_MISSING',
                suggestion: `Provide a value of type '${parameter.type}'`
            });
            return {
                valid: false,
                errors,
                warnings
            };
        }
        // Skip validation for optional missing parameters
        if (!parameter.required && (value === undefined || value === null)) {
            return {
                valid: true,
                errors: [],
                warnings: []
            };
        }
        // Validate parameter type
        const typeValidation = await this.validateType(parameter, value, context);
        if (!typeValidation.valid) {
            errors.push(...typeValidation.errors);
        }
        else {
            validatedValue = typeValidation.value;
        }
        warnings.push(...typeValidation.warnings);
        // Apply additional validation rules if type validation passed
        if (typeValidation.valid) {
            const rulesValidation = await this.applyValidationRules(parameter, validatedValue, context);
            if (!rulesValidation.valid) {
                errors.push(...rulesValidation.errors);
            }
            warnings.push(...rulesValidation.warnings);
        }
        return {
            valid: errors.length === 0,
            errors,
            warnings,
            value: validatedValue
        };
    }
    /**
     * Validates parameter type.
     *
     * @param parameter Parameter definition
     * @param value Value to validate
     * @param context Validation context
     * @returns Promise that resolves to validation result
     */
    async validateType(parameter, value, context) {
        const errors = [];
        const warnings = [];
        let validatedValue = value;
        const expectedType = parameter.type.toLowerCase();
        const actualType = typeof value;
        switch (expectedType) {
            case 'string':
                if (actualType !== 'string') {
                    // Try to convert to string
                    try {
                        validatedValue = String(value);
                        warnings.push({
                            parameterName: parameter.name,
                            message: `Parameter '${parameter.name}' was converted from ${actualType} to string`,
                            code: 'TYPE_CONVERSION'
                        });
                    }
                    catch (error) {
                        errors.push({
                            parameterName: parameter.name,
                            message: `Parameter '${parameter.name}' must be a string, got ${actualType}`,
                            code: 'TYPE_MISMATCH',
                            suggestion: 'Provide a string value'
                        });
                    }
                }
                break;
            case 'number':
                if (actualType !== 'number') {
                    // Try to convert to number
                    const numValue = Number(value);
                    if (!isNaN(numValue)) {
                        validatedValue = numValue;
                        warnings.push({
                            parameterName: parameter.name,
                            message: `Parameter '${parameter.name}' was converted from ${actualType} to number`,
                            code: 'TYPE_CONVERSION'
                        });
                    }
                    else {
                        errors.push({
                            parameterName: parameter.name,
                            message: `Parameter '${parameter.name}' must be a number, got ${actualType}`,
                            code: 'TYPE_MISMATCH',
                            suggestion: 'Provide a numeric value'
                        });
                    }
                }
                break;
            case 'boolean':
                if (actualType !== 'boolean') {
                    // Try to convert to boolean
                    if (value === 'true' || value === '1' || value === 1) {
                        validatedValue = true;
                        warnings.push({
                            parameterName: parameter.name,
                            message: `Parameter '${parameter.name}' was converted to boolean true`,
                            code: 'TYPE_CONVERSION'
                        });
                    }
                    else if (value === 'false' || value === '0' || value === 0) {
                        validatedValue = false;
                        warnings.push({
                            parameterName: parameter.name,
                            message: `Parameter '${parameter.name}' was converted to boolean false`,
                            code: 'TYPE_CONVERSION'
                        });
                    }
                    else {
                        errors.push({
                            parameterName: parameter.name,
                            message: `Parameter '${parameter.name}' must be a boolean, got ${actualType}`,
                            code: 'TYPE_MISMATCH',
                            suggestion: 'Provide true or false'
                        });
                    }
                }
                break;
            case 'object':
                if (actualType !== 'object' || value === null) {
                    errors.push({
                        parameterName: parameter.name,
                        message: `Parameter '${parameter.name}' must be an object, got ${actualType}`,
                        code: 'TYPE_MISMATCH',
                        suggestion: 'Provide an object value'
                    });
                }
                break;
            case 'array':
                if (!Array.isArray(value)) {
                    errors.push({
                        parameterName: parameter.name,
                        message: `Parameter '${parameter.name}' must be an array, got ${actualType}`,
                        code: 'TYPE_MISMATCH',
                        suggestion: 'Provide an array value'
                    });
                }
                break;
            case 'vscode.uri':
                const uriValidation = this.validateVSCodeUri(parameter, value);
                if (!uriValidation.valid) {
                    errors.push(...uriValidation.errors);
                }
                else {
                    validatedValue = uriValidation.value;
                }
                warnings.push(...uriValidation.warnings);
                break;
            case 'vscode.uri[]':
                if (!Array.isArray(value)) {
                    errors.push({
                        parameterName: parameter.name,
                        message: `Parameter '${parameter.name}' must be an array of URIs`,
                        code: 'TYPE_MISMATCH',
                        suggestion: 'Provide an array of vscode.Uri objects or file paths'
                    });
                }
                else {
                    const uriArray = [];
                    for (let i = 0; i < value.length; i++) {
                        const uriValidation = this.validateVSCodeUri(parameter, value[i]);
                        if (uriValidation.valid && uriValidation.value) {
                            uriArray.push(uriValidation.value);
                        }
                        else {
                            errors.push({
                                parameterName: parameter.name,
                                message: `Array element ${i} is not a valid URI`,
                                code: 'INVALID_URI_ARRAY_ELEMENT',
                                suggestion: 'Provide valid file paths or vscode.Uri objects'
                            });
                        }
                    }
                    if (errors.length === 0) {
                        validatedValue = uriArray;
                    }
                }
                break;
            default:
                // Handle union types and complex types
                if (expectedType.includes('|')) {
                    const unionTypes = expectedType.split('|').map(t => t.trim());
                    let validForAnyType = false;
                    for (const unionType of unionTypes) {
                        const unionValidation = await this.validateType({ ...parameter, type: unionType }, value, context);
                        if (unionValidation.valid) {
                            validForAnyType = true;
                            validatedValue = unionValidation.value;
                            warnings.push(...unionValidation.warnings);
                            break;
                        }
                    }
                    if (!validForAnyType) {
                        errors.push({
                            parameterName: parameter.name,
                            message: `Parameter '${parameter.name}' must be one of: ${unionTypes.join(', ')}, got ${actualType}`,
                            code: 'UNION_TYPE_MISMATCH',
                            suggestion: `Provide a value matching one of: ${unionTypes.join(', ')}`
                        });
                    }
                }
                else {
                    warnings.push({
                        parameterName: parameter.name,
                        message: `Unknown type '${expectedType}' for parameter '${parameter.name}', skipping type validation`,
                        code: 'UNKNOWN_TYPE'
                    });
                }
                break;
        }
        return {
            valid: errors.length === 0,
            errors,
            warnings,
            value: validatedValue
        };
    }
    /**
     * Validates a VS Code URI parameter.
     *
     * @param parameter Parameter definition
     * @param value Value to validate
     * @returns Validation result
     */
    validateVSCodeUri(parameter, value) {
        const errors = [];
        const warnings = [];
        let validatedValue = value;
        if (value instanceof vscode.Uri) {
            // Already a valid URI
            return {
                valid: true,
                errors: [],
                warnings: [],
                value
            };
        }
        if (typeof value === 'string') {
            try {
                // Try to parse as file path
                if (value.startsWith('/') || value.includes('\\') || value.includes(':')) {
                    validatedValue = vscode.Uri.file(value);
                    warnings.push({
                        parameterName: parameter.name,
                        message: `String path '${value}' was converted to vscode.Uri`,
                        code: 'PATH_TO_URI_CONVERSION'
                    });
                }
                else {
                    // Try to parse as URI
                    validatedValue = vscode.Uri.parse(value);
                    warnings.push({
                        parameterName: parameter.name,
                        message: `String '${value}' was parsed as URI`,
                        code: 'STRING_TO_URI_CONVERSION'
                    });
                }
            }
            catch (error) {
                errors.push({
                    parameterName: parameter.name,
                    message: `Cannot convert '${value}' to vscode.Uri: ${error}`,
                    code: 'INVALID_URI_FORMAT',
                    suggestion: 'Provide a valid file path or URI string'
                });
            }
        }
        else {
            errors.push({
                parameterName: parameter.name,
                message: `Parameter '${parameter.name}' must be a vscode.Uri or string path, got ${typeof value}`,
                code: 'INVALID_URI_TYPE',
                suggestion: 'Provide a vscode.Uri object or file path string'
            });
        }
        return {
            valid: errors.length === 0,
            errors,
            warnings,
            value: validatedValue
        };
    }
    /**
     * Applies additional validation rules to a parameter.
     *
     * @param parameter Parameter definition
     * @param value Validated value
     * @param context Validation context
     * @returns Promise that resolves to validation result
     */
    async applyValidationRules(parameter, value, context) {
        const errors = [];
        const warnings = [];
        // Apply built-in validation rules based on parameter type and context
        if (parameter.type === 'string' && typeof value === 'string') {
            // String length validation
            if (value.length === 0 && parameter.required) {
                errors.push({
                    parameterName: parameter.name,
                    message: `Required string parameter '${parameter.name}' cannot be empty`,
                    code: 'EMPTY_REQUIRED_STRING',
                    suggestion: 'Provide a non-empty string value'
                });
            }
            // Very long strings might be problematic
            if (value.length > 10000) {
                warnings.push({
                    parameterName: parameter.name,
                    message: `String parameter '${parameter.name}' is very long (${value.length} characters)`,
                    code: 'VERY_LONG_STRING'
                });
            }
        }
        if (parameter.type === 'vscode.Uri' && value instanceof vscode.Uri) {
            // File existence validation for file URIs
            if (value.scheme === 'file') {
                try {
                    await vscode.workspace.fs.stat(value);
                }
                catch (error) {
                    warnings.push({
                        parameterName: parameter.name,
                        message: `File '${value.fsPath}' does not exist`,
                        code: 'FILE_NOT_FOUND'
                    });
                }
            }
        }
        return {
            valid: errors.length === 0,
            errors,
            warnings
        };
    }
    /**
     * Creates default validation rules for common parameter types.
     *
     * @param parameter Parameter definition
     * @returns Array of validation rules
     */
    createDefaultValidationRules(parameter) {
        const rules = [];
        // Required parameter rule
        if (parameter.required) {
            rules.push({
                type: 'custom',
                config: { checkRequired: true },
                errorMessage: `Parameter '${parameter.name}' is required`,
                required: true
            });
        }
        // Type-specific rules
        switch (parameter.type.toLowerCase()) {
            case 'string':
                rules.push({
                    type: 'type',
                    config: { expectedType: 'string' },
                    errorMessage: `Parameter '${parameter.name}' must be a string`,
                    required: true
                });
                break;
            case 'number':
                rules.push({
                    type: 'type',
                    config: { expectedType: 'number' },
                    errorMessage: `Parameter '${parameter.name}' must be a number`,
                    required: true
                });
                break;
            case 'boolean':
                rules.push({
                    type: 'type',
                    config: { expectedType: 'boolean' },
                    errorMessage: `Parameter '${parameter.name}' must be a boolean`,
                    required: true
                });
                break;
        }
        return rules;
    }
    /**
     * Generates user-friendly error messages for validation failures.
     *
     * @param errors Array of validation errors
     * @returns Formatted error message
     */
    formatValidationErrors(errors) {
        if (errors.length === 0) {
            return 'No validation errors';
        }
        const messages = [];
        for (const error of errors) {
            let message = `• ${error.message}`;
            if (error.suggestion) {
                message += ` (${error.suggestion})`;
            }
            messages.push(message);
        }
        return `Validation failed:\n${messages.join('\n')}`;
    }
    /**
     * Generates user-friendly warning messages.
     *
     * @param warnings Array of validation warnings
     * @returns Formatted warning message
     */
    formatValidationWarnings(warnings) {
        if (warnings.length === 0) {
            return 'No validation warnings';
        }
        const messages = warnings.map(warning => `• ${warning.message}`);
        return `Validation warnings:\n${messages.join('\n')}`;
    }
}
exports.ParameterValidator = ParameterValidator;
//# sourceMappingURL=parameter-validator.js.map