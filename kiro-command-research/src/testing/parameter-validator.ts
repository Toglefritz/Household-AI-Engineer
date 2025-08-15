/**
 * Parameter validation system for testing Kiro commands safely.
 * 
 * This module provides comprehensive parameter validation capabilities
 * to ensure safe command testing and accurate parameter discovery.
 */

import * as vscode from 'vscode';
import { ParameterInfo } from '../types/command-metadata';

/**
 * Validation rule for parameter values.
 */
export interface ValidationRule {
  /** Type of validation to perform */
  readonly type: 'type' | 'range' | 'pattern' | 'enum' | 'custom';
  
  /** Rule-specific configuration */
  readonly config: Record<string, any>;
  
  /** Error message when validation fails */
  readonly errorMessage: string;
  
  /** Whether this rule is required or optional */
  readonly required: boolean;
}

/**
 * Result of parameter validation.
 */
export interface ValidationResult {
  /** Whether validation passed */
  readonly valid: boolean;
  
  /** Validation error messages */
  readonly errors: ValidationError[];
  
  /** Warnings (non-blocking issues) */
  readonly warnings: ValidationWarning[];
  
  /** Validated and potentially transformed parameter value */
  readonly value?: any;
}

/**
 * Validation error information.
 */
export interface ValidationError {
  /** Parameter name that failed validation */
  readonly parameterName: string;
  
  /** Error message */
  readonly message: string;
  
  /** Error code for programmatic handling */
  readonly code: string;
  
  /** Suggested fix or alternative */
  readonly suggestion?: string;
}

/**
 * Validation warning information.
 */
export interface ValidationWarning {
  /** Parameter name */
  readonly parameterName: string;
  
  /** Warning message */
  readonly message: string;
  
  /** Warning code */
  readonly code: string;
}

/**
 * Parameter validation context.
 */
export interface ValidationContext {
  /** Command ID being validated */
  readonly commandId: string;
  
  /** Current workspace context */
  readonly workspace?: vscode.WorkspaceFolder;
  
  /** Active editor context */
  readonly activeEditor?: vscode.TextEditor;
  
  /** Additional context data */
  readonly context: Record<string, any>;
}

/**
 * Validates command parameters with comprehensive type checking and rules.
 * 
 * The ParameterValidator provides safe parameter validation for command testing,
 * ensuring that parameters meet expected types and constraints before execution.
 */
export class ParameterValidator {
  
  /**
   * Validates a set of parameters against their definitions.
   * 
   * @param parameters Parameter definitions to validate against
   * @param values Parameter values to validate
   * @param context Validation context
   * @returns Promise that resolves to validation results
   */
  public async validateParameters(
    parameters: ParameterInfo[],
    values: Record<string, any>,
    context: ValidationContext
  ): Promise<ValidationResult> {
    const errors: ValidationError[] = [];
    const warnings: ValidationWarning[] = [];
    const validatedValues: Record<string, any> = {};
    
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
    
    const result: ValidationResult = {
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
  public async validateParameter(
    parameter: ParameterInfo,
    value: any,
    context: ValidationContext
  ): Promise<ValidationResult> {
    const errors: ValidationError[] = [];
    const warnings: ValidationWarning[] = [];
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
    } else {
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
  private async validateType(
    parameter: ParameterInfo,
    value: any,
    context: ValidationContext
  ): Promise<ValidationResult> {
    const errors: ValidationError[] = [];
    const warnings: ValidationWarning[] = [];
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
          } catch (error) {
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
          } else {
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
          } else if (value === 'false' || value === '0' || value === 0) {
            validatedValue = false;
            warnings.push({
              parameterName: parameter.name,
              message: `Parameter '${parameter.name}' was converted to boolean false`,
              code: 'TYPE_CONVERSION'
            });
          } else {
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
        } else {
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
        } else {
          const uriArray: vscode.Uri[] = [];
          for (let i = 0; i < value.length; i++) {
            const uriValidation = this.validateVSCodeUri(parameter, value[i]);
            if (uriValidation.valid && uriValidation.value) {
              uriArray.push(uriValidation.value);
            } else {
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
            const unionValidation = await this.validateType(
              { ...parameter, type: unionType },
              value,
              context
            );
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
        } else {
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
  private validateVSCodeUri(parameter: ParameterInfo, value: any): ValidationResult {
    const errors: ValidationError[] = [];
    const warnings: ValidationWarning[] = [];
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
        } else {
          // Try to parse as URI
          validatedValue = vscode.Uri.parse(value);
          warnings.push({
            parameterName: parameter.name,
            message: `String '${value}' was parsed as URI`,
            code: 'STRING_TO_URI_CONVERSION'
          });
        }
      } catch (error) {
        errors.push({
          parameterName: parameter.name,
          message: `Cannot convert '${value}' to vscode.Uri: ${error}`,
          code: 'INVALID_URI_FORMAT',
          suggestion: 'Provide a valid file path or URI string'
        });
      }
    } else {
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
  private async applyValidationRules(
    parameter: ParameterInfo,
    value: any,
    context: ValidationContext
  ): Promise<ValidationResult> {
    const errors: ValidationError[] = [];
    const warnings: ValidationWarning[] = [];
    
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
        } catch (error) {
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
  public createDefaultValidationRules(parameter: ParameterInfo): ValidationRule[] {
    const rules: ValidationRule[] = [];
    
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
  public formatValidationErrors(errors: ValidationError[]): string {
    if (errors.length === 0) {
      return 'No validation errors';
    }
    
    const messages: string[] = [];
    
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
  public formatValidationWarnings(warnings: ValidationWarning[]): string {
    if (warnings.length === 0) {
      return 'No validation warnings';
    }
    
    const messages: string[] = warnings.map(warning => `• ${warning.message}`);
    return `Validation warnings:\n${messages.join('\n')}`;
  }
}