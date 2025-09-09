import 'package:dwellware/services/application_launcher/application_launcher_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// Test suite for LaunchException enhanced error handling functionality.
///
/// This test suite verifies that the enhanced LaunchException class properly
/// handles error context, searched paths, access errors, and provides
/// comprehensive error reporting for debugging and user feedback.
void main() {
  group('LaunchException', () {
    group('basic functionality', () {
      /// Verifies that basic LaunchException creation works correctly.
      ///
      /// Tests the fundamental constructor and ensures that basic properties
      /// are properly set and accessible.
      test('should create basic exception with message and code', () {
        const LaunchException exception = LaunchException(
          'Test error message',
          'TEST_ERROR',
        );

        expect(exception.message, equals('Test error message'));
        expect(exception.code, equals('TEST_ERROR'));
        expect(exception.searchedPaths, isNull);
        expect(exception.accessErrors, isNull);
        expect(exception.cause, isNull);
        expect(exception.context, isEmpty);
        expect(exception.hasSearchContext, isFalse);
        expect(exception.hasAccessErrors, isFalse);
      });

      /// Verifies that LaunchException with full context works correctly.
      ///
      /// Tests the enhanced constructor with all optional parameters to ensure
      /// comprehensive error information is properly stored and accessible.
      test('should create exception with full context information', () {
        final List<String> searchedPaths = [
          '/app/index.html',
          '/app/src/index.html',
          '/app/public/index.html',
        ];
        final List<String> accessErrors = [
          '/app/src/index.html: Permission denied',
          '/app/public/index.html: File not readable',
        ];
        final Map<String, dynamic> context = {
          'applicationId': 'test-app',
          'timestamp': DateTime.now().toIso8601String(),
        };
        final Exception cause = Exception('Underlying file system error');

        final LaunchException exception = LaunchException(
          'Comprehensive error message',
          'COMPREHENSIVE_ERROR',
          searchedPaths: searchedPaths,
          accessErrors: accessErrors,
          context: context,
          cause: cause,
        );

        expect(exception.message, equals('Comprehensive error message'));
        expect(exception.code, equals('COMPREHENSIVE_ERROR'));
        expect(exception.searchedPaths, equals(searchedPaths));
        expect(exception.accessErrors, equals(accessErrors));
        expect(exception.context, equals(context));
        expect(exception.cause, equals(cause));
        expect(exception.hasSearchContext, isTrue);
        expect(exception.hasAccessErrors, isTrue);
      });
    });

    group('factory constructors', () {
      /// Verifies the fileNotFound factory constructor creates proper exceptions.
      ///
      /// Tests that the factory method generates comprehensive error messages
      /// with all searched paths and access errors properly formatted.
      test('should create fileNotFound exception with comprehensive message', () {
        final List<String> searchedPaths = [
          '/app/index.html',
          '/app/src/index.html',
          '/app/public/index.html',
          '/app/dist/index.html',
          '/app/build/index.html',
        ];
        final List<String> accessErrors = [
          '/app/src/index.html: Permission denied',
          '/app/dist/index.html: File corrupted',
        ];

        final LaunchException exception = LaunchException.fileNotFound(
          applicationId: 'test-app-123',
          searchedPaths: searchedPaths,
          accessErrors: accessErrors,
        );

        expect(exception.code, equals('INDEX_NOT_FOUND'));
        expect(exception.searchedPaths, equals(searchedPaths));
        expect(exception.accessErrors, equals(accessErrors));
        expect(exception.hasSearchContext, isTrue);
        expect(exception.hasAccessErrors, isTrue);

        // Verify the message contains all expected information
        expect(exception.message, contains('test-app-123'));
        expect(exception.message, contains('Searched locations:'));
        expect(exception.message, contains('Access errors encountered:'));
        expect(exception.message, contains('/app/index.html'));
        expect(exception.message, contains('/app/src/index.html'));
        expect(exception.message, contains('Permission denied'));
        expect(exception.message, contains('File corrupted'));

        // Verify context information
        expect(exception.context['applicationId'], equals('test-app-123'));
        expect(exception.context['searchCount'], equals(5));
        expect(exception.context['accessErrorCount'], equals(2));
      });

      /// Verifies the fileNotFound factory works without access errors.
      ///
      /// Tests that the factory method handles cases where no access errors
      /// occurred during the search process.
      test('should create fileNotFound exception without access errors', () {
        final List<String> searchedPaths = [
          '/app/index.html',
          '/app/src/index.html',
        ];

        final LaunchException exception = LaunchException.fileNotFound(
          applicationId: 'simple-app',
          searchedPaths: searchedPaths,
        );

        expect(exception.code, equals('INDEX_NOT_FOUND'));
        expect(exception.searchedPaths, equals(searchedPaths));
        expect(exception.accessErrors, isNull);
        expect(exception.hasSearchContext, isTrue);
        expect(exception.hasAccessErrors, isFalse);

        // Verify the message doesn't contain access errors section
        expect(exception.message, contains('simple-app'));
        expect(exception.message, contains('Searched locations:'));
        expect(exception.message, isNot(contains('Access errors encountered:')));

        // Verify context information
        expect(exception.context['applicationId'], equals('simple-app'));
        expect(exception.context['searchCount'], equals(2));
        expect(exception.context['accessErrorCount'], equals(0));
      });

      /// Verifies the fileAccessDenied factory constructor works correctly.
      ///
      /// Tests that permission-related errors are properly formatted with
      /// helpful user guidance and technical context.
      test('should create fileAccessDenied exception with proper context', () {
        const String filePath = '/restricted/app/index.html';
        final Exception cause = Exception('Permission denied by OS');

        final LaunchException exception = LaunchException.fileAccessDenied(
          filePath: filePath,
          cause: cause,
        );

        expect(exception.code, equals('FILE_ACCESS_DENIED'));
        expect(exception.cause, equals(cause));
        expect(exception.message, contains(filePath));
        expect(exception.message, contains('permission restrictions'));
        expect(exception.message, contains('read permissions'));

        // Verify context information
        expect(exception.context['filePath'], equals(filePath));
        expect(exception.context['errorType'], equals('permission_denied'));
      });

      /// Verifies the invalidFile factory constructor works correctly.
      ///
      /// Tests that file validation errors are properly formatted with
      /// information about expected content types and validation failures.
      test('should create invalidFile exception with validation context', () {
        const String filePath = '/app/invalid.html';
        const String expectedType = 'HTML';
        final Exception cause = Exception('Missing DOCTYPE declaration');

        final LaunchException exception = LaunchException.invalidFile(
          filePath: filePath,
          expectedType: expectedType,
          cause: cause,
        );

        expect(exception.code, equals('INVALID_FILE_CONTENT'));
        expect(exception.cause, equals(cause));
        expect(exception.message, contains(filePath));
        expect(exception.message, contains('HTML content'));
        expect(exception.message, contains('properly formatted HTML'));

        // Verify context information
        expect(exception.context['filePath'], equals(filePath));
        expect(exception.context['expectedType'], equals(expectedType));
        expect(exception.context['errorType'], equals('invalid_content'));
      });

      /// Verifies the symbolicLinkError factory constructor for circular references.
      ///
      /// Tests that circular symbolic link errors are properly formatted with
      /// helpful error messages and appropriate context information.
      test('should create symbolicLinkError exception for circular reference', () {
        const String filePath = '/app/circular-link.html';
        final Exception cause = Exception('Circular reference detected');

        final LaunchException exception = LaunchException.symbolicLinkError(
          filePath: filePath,
          errorType: 'circular_reference',
          cause: cause,
        );

        expect(exception.code, equals('SYMBOLIC_LINK_ERROR'));
        expect(exception.cause, equals(cause));
        expect(exception.message, contains(filePath));
        expect(exception.message, contains('Circular symbolic link reference'));
        expect(exception.message, contains('loop that prevents resolution'));

        // Verify context information
        expect(exception.context['filePath'], equals(filePath));
        expect(exception.context['errorType'], equals('circular_reference'));
        expect(exception.context['category'], equals('symbolic_link'));
      });

      /// Verifies the symbolicLinkError factory constructor for broken links.
      ///
      /// Tests that broken symbolic link errors are properly formatted with
      /// helpful error messages about non-existent targets.
      test('should create symbolicLinkError exception for broken link', () {
        const String filePath = '/app/broken-link.html';
        final Exception cause = Exception('Target does not exist');

        final LaunchException exception = LaunchException.symbolicLinkError(
          filePath: filePath,
          errorType: 'broken_link',
          cause: cause,
        );

        expect(exception.code, equals('SYMBOLIC_LINK_ERROR'));
        expect(exception.cause, equals(cause));
        expect(exception.message, contains(filePath));
        expect(exception.message, contains('points to non-existent target'));
        expect(exception.message, contains('target does not exist'));

        // Verify context information
        expect(exception.context['filePath'], equals(filePath));
        expect(exception.context['errorType'], equals('broken_link'));
        expect(exception.context['category'], equals('symbolic_link'));
      });

      /// Verifies the symbolicLinkError factory constructor for excessive recursion.
      ///
      /// Tests that deep symbolic link chain errors are properly formatted with
      /// helpful error messages about resolution depth limits.
      test('should create symbolicLinkError exception for excessive recursion', () {
        const String filePath = '/app/deep-link.html';
        final Exception cause = Exception('Maximum depth exceeded');

        final LaunchException exception = LaunchException.symbolicLinkError(
          filePath: filePath,
          errorType: 'excessive_recursion',
          cause: cause,
        );

        expect(exception.code, equals('SYMBOLIC_LINK_ERROR'));
        expect(exception.cause, equals(cause));
        expect(exception.message, contains(filePath));
        expect(exception.message, contains('chain too deep'));
        expect(exception.message, contains('maximum resolution depth'));

        // Verify context information
        expect(exception.context['filePath'], equals(filePath));
        expect(exception.context['errorType'], equals('excessive_recursion'));
        expect(exception.context['category'], equals('symbolic_link'));
      });

      /// Verifies the symbolicLinkError factory constructor for generic errors.
      ///
      /// Tests that generic symbolic link errors are properly formatted with
      /// fallback error messages for unknown error types.
      test('should create symbolicLinkError exception for generic error', () {
        const String filePath = '/app/generic-link.html';
        final Exception cause = Exception('Unknown symbolic link error');

        final LaunchException exception = LaunchException.symbolicLinkError(
          filePath: filePath,
          errorType: 'unknown_error',
          cause: cause,
        );

        expect(exception.code, equals('SYMBOLIC_LINK_ERROR'));
        expect(exception.cause, equals(cause));
        expect(exception.message, contains(filePath));
        expect(exception.message, contains('Failed to resolve symbolic link'));
        expect(exception.message, contains('error occurred while following'));

        // Verify context information
        expect(exception.context['filePath'], equals(filePath));
        expect(exception.context['errorType'], equals('unknown_error'));
        expect(exception.context['category'], equals('symbolic_link'));
      });
    });

    group('detailed reporting', () {
      /// Verifies that the detailed report includes all available information.
      ///
      /// Tests that the detailedReport getter produces comprehensive output
      /// suitable for logging and debugging purposes.
      test('should generate comprehensive detailed report', () {
        final List<String> searchedPaths = [
          '/app/index.html',
          '/app/src/index.html',
        ];
        final List<String> accessErrors = [
          '/app/src/index.html: Permission denied',
        ];
        final Map<String, dynamic> context = {
          'applicationId': 'test-app',
          'userId': 'user-123',
        };
        final Exception cause = Exception('File system error');

        final LaunchException exception = LaunchException(
          'Test error for detailed report',
          'DETAILED_TEST_ERROR',
          searchedPaths: searchedPaths,
          accessErrors: accessErrors,
          context: context,
          cause: cause,
        );

        final String report = exception.detailedReport;

        // Verify all sections are present
        expect(report, contains('LaunchException Details:'));
        expect(report, contains('Code: DETAILED_TEST_ERROR'));
        expect(report, contains('Message: Test error for detailed report'));
        expect(report, contains('Searched Paths (2):'));
        expect(report, contains('1. /app/index.html'));
        expect(report, contains('2. /app/src/index.html'));
        expect(report, contains('Access Errors (1):'));
        expect(report, contains('1. /app/src/index.html: Permission denied'));
        expect(report, contains('Additional Context:'));
        expect(report, contains('applicationId: test-app'));
        expect(report, contains('userId: user-123'));
        expect(report, contains('Underlying Cause:'));
        expect(report, contains('Exception: File system error'));
      });

      /// Verifies that the detailed report works with minimal information.
      ///
      /// Tests that the detailedReport getter handles cases where only
      /// basic error information is available.
      test('should generate minimal detailed report for basic exception', () {
        const LaunchException exception = LaunchException(
          'Simple error message',
          'SIMPLE_ERROR',
        );

        final String report = exception.detailedReport;

        expect(report, contains('LaunchException Details:'));
        expect(report, contains('Code: SIMPLE_ERROR'));
        expect(report, contains('Message: Simple error message'));
        expect(report, isNot(contains('Searched Paths')));
        expect(report, isNot(contains('Access Errors')));
        expect(report, isNot(contains('Additional Context')));
        expect(report, isNot(contains('Underlying Cause')));
      });
    });

    group('toString method', () {
      /// Verifies that toString provides concise error identification.
      ///
      /// Tests that the toString method returns a properly formatted
      /// string suitable for logging and error identification.
      test('should provide concise string representation', () {
        const LaunchException exception = LaunchException(
          'Test error message',
          'TEST_ERROR_CODE',
        );

        final String stringRepresentation = exception.toString();

        expect(stringRepresentation, equals('LaunchException(TEST_ERROR_CODE): Test error message'));
      });
    });
  });
}
