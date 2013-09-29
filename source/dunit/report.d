/**
 * Module to handle reporting.
 *
 * License:
 *     MIT. See LICENSE for full details.
 */
module dunit.report;

/**
 * Imports.
 */
import core.exception;
import core.runtime;
import dunit.exception;
import dunit.output.console;

/**
 * A class to collate unit test information and present a report.
 */
class ResultCollator
{
	/**
	 * Collection of results.
	 *
	 * Null elements are successfully run tests.
	 */
	private DUnitAssertError[string] _results;

	/**
	 * Bool representing if all tests passed successfully.
	 */
	private bool _resultsSuccessful = true;

	/**
	 * Return a boolean representing if the unit tests ran successfully.
	 *
	 * Returns:
	 *     true if the tests ran successfully, false if not.
	 */
	public @property bool resultsSuccessful()
	{
		return this._resultsSuccessful;
	}

	/**
	 * Add a result to the collator.
	 *
	 * Params:
	 *     moduleName = The module where the error occurred.
	 *     error = The error raised from the toolkit.
	 */
	public void addResult(string moduleName, DUnitAssertError error = null)
	{
		this._resultsSuccessful   = this._resultsSuccessful && (error is null);
		this._results[moduleName] = error;
	}

	/**
	 * Get the results.
	 *
	 * Returns:
	 *     An array containing the results.
	 */
	public DUnitAssertError[string] getResults()
	{
		return this._results;
	}
}

/**
 * Replace the standard unit test handler.
 */
shared static this()
{
	Runtime.moduleUnitTester = function()
	{
		auto collator = new ResultCollator();
		auto console  = new Console();

		console.writeHeader();

		foreach (module_; ModuleInfo)
		{
			if (module_)
			{
				auto unitTest = module_.unitTest;

				if (unitTest)
				{
					try
					{
						unitTest();
					}
					catch (DUnitAssertError ex)
					{
						collator.addResult(module_.name, ex);
						continue;
					}
					catch (AssertError ex)
					{
						collator.addResult(module_.name, new DUnitAssertError(ex.msg, ex.file, ex.line));
						continue;
					}
					collator.addResult(module_.name);
				}
			}
		}

		if (collator.resultsSuccessful)
		{
			console.writeSuccessMessage();
		}
		else
		{
			console.writeFailMessage();
			console.writeDetailedResults(collator.getResults());
		}

		return collator.resultsSuccessful;
	};
}
