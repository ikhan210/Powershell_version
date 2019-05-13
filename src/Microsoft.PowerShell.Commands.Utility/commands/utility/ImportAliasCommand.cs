// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.IO;
using System.Management.Automation;
using System.Management.Automation.Internal;
using System.Security;
using System.Text;

namespace Microsoft.PowerShell.Commands
{
    /// <summary>
    /// The implementation of the "import-alias" cmdlet.
    /// </summary>
    [Cmdlet(VerbsData.Import, "Alias", SupportsShouldProcess = true, DefaultParameterSetName = "ByPath", HelpUri = "https://go.microsoft.com/fwlink/?LinkID=113339")]
    [OutputType(typeof(AliasInfo))]
    public class ImportAliasCommand : PSCmdlet
    {
        #region Statics

        private const string LiteralPathParameterSetName = "ByLiteralPath";

        #endregion

        #region Parameters

        /// <summary>
        /// The path from which to import the aliases.
        /// </summary>
        [Parameter(Position = 0, Mandatory = true, ValueFromPipeline = true, ValueFromPipelineByPropertyName = true, ParameterSetName = "ByPath")]
        public string Path { get; set; }

        /// <summary>
        /// The literal path from which to import the aliases.
        /// </summary>
        [Parameter(Mandatory = true, ValueFromPipeline = true, ValueFromPipelineByPropertyName = true, ParameterSetName = LiteralPathParameterSetName)]
        [Alias("PSPath", "LP")]
        public string LiteralPath
        {
            get
            {
                return Path;
            }

            set
            {
                Path = value;
            }
        }

        /// <summary>
        /// The scope to import the aliases to.
        /// </summary>
        [Parameter]
        [ValidateNotNullOrEmpty]
        public string Scope { get; set; }

        /// <summary>
        /// If set to true, the alias that is set is passed to the pipeline.
        /// </summary>
        [Parameter]
        public SwitchParameter PassThru
        {
            get
            {
                return _passThru;
            }

            set
            {
                _passThru = value;
            }
        }

        private bool _passThru;

        /// <summary>
        /// If set to true and an existing alias of the same name exists
        /// and is ReadOnly, the alias will be overwritten.
        /// </summary>
        [Parameter]
        public SwitchParameter Force
        {
            get
            {
                return _force;
            }

            set
            {
                _force = value;
            }
        }

        private bool _force;

        #endregion Parameters

        #region Command code
        
        private static bool OnlyContainsWhitespace(string line)
        {
            bool result = true;

            foreach (char c in line)
            {
                if (char.IsWhiteSpace(c) && c != '\n' && c != '\r')
                {
                    continue;
                }

                result = false;
                break;
            }

            return result;
        }
      
        private static Collection<string> ParseCsvLine(string csv)
        {        
            string csvTrimmed = csv.Trim();
            Collection<string> result = new Collection<string>();
            StringBuilder wordBuffer = new StringBuilder();

            for (int i = 0; i < csvTrimmed.Length; i++) 
            {
                char nextChar = csvTrimmed[i];

                // if next character was delimiter or we are at the end, add string to result and clear wordBuffer
                // else if next character was quote, perform reading until next quote and add it to wordBuffer
                // else read and add it to wordBuffer
                if (nextChar == ',') 
                {
                    result.Add(wordBuffer.ToString());
                    wordBuffer.Clear();
                } 
                else if (nextChar == '"') 
                {
                    bool inQuotes = true;
                    
                    // if we are within a quote section, read and append to wordBuffer until we find a next quote that is not followed by another quote
                    // if it is a single quote, escape the quote section
                    // if the quote is followed by an other quote, do not escape and add a quote character to wordBuffer
                    while (i < csvTrimmed.Length && inQuotes) 
                    {
                        i++;
                        nextChar = csvTrimmed[i];
                        
                        if (nextChar == '"') 
                        {
                            if (i + 1 < csvTrimmed.Length && csvTrimmed[i + 1] == '"')
                            {
                                wordBuffer.Append(nextChar);
                                i++;
                            } 
                            else 
                            {
                                inQuotes = false;
                            }
                        } 
                        else 
                        {
                            wordBuffer.Append(nextChar);
                        }
                    }
                } 
                else 
                {
                    wordBuffer.Append(nextChar);
                }
            }

            string lastWord = wordBuffer.ToString();
            if (lastWord != string.Empty)
            {
                result.Add(lastWord);
            }

            return result;           
        }
        
        private static bool LineShouldBeSkipped(string line)
        {
            // if line is empty or a comment, return true
            return line.Length == 0 || line[0] == '#' || OnlyContainsWhitespace(line);
        }

        /// <summary>
        /// The main processing loop of the command.
        /// </summary>
        protected override void ProcessRecord()
        {
            Collection<AliasInfo> importedAliases = GetAliasesFromFile(this.ParameterSetName.Equals(LiteralPathParameterSetName,
                StringComparison.OrdinalIgnoreCase));

            CommandOrigin origin = MyInvocation.CommandOrigin;

            foreach (AliasInfo alias in importedAliases)
            {
                // If not force, then see if the alias already exists

                // NTRAID#Windows Out Of Band Releases-906910-2006/03/17-JonN
                string action = AliasCommandStrings.ImportAliasAction;

                string target = StringUtil.Format(AliasCommandStrings.ImportAliasTarget, alias.Name, alias.Definition);

                if (!ShouldProcess(target, action))
                    continue;

                if (!Force)
                {
                    AliasInfo existingAlias = null;
                    if (string.IsNullOrEmpty(Scope))
                    {
                        existingAlias = SessionState.Internal.GetAlias(alias.Name);
                    }
                    else
                    {
                        existingAlias = SessionState.Internal.GetAliasAtScope(alias.Name, Scope);
                    }

                    if (existingAlias != null)
                    {
                        // Write an error for aliases that aren't visible...
                        try
                        {
                            SessionState.ThrowIfNotVisible(origin, existingAlias);
                        }
                        catch (SessionStateException sessionStateException)
                        {
                            WriteError(
                                new ErrorRecord(
                                    sessionStateException.ErrorRecord,
                                    sessionStateException));
                            // Only report the error once...
                            continue;
                        }

                        // Since the alias already exists, write an error.

                        SessionStateException aliasExists =
                            new SessionStateException(
                                alias.Name,
                                SessionStateCategory.Alias,
                                "AliasAlreadyExists",
                                SessionStateStrings.AliasAlreadyExists,
                                ErrorCategory.ResourceExists);

                        WriteError(
                            new ErrorRecord(
                                aliasExists.ErrorRecord,
                                aliasExists));
                        continue;
                    }

                    if (VerifyShadowingExistingCommandsAndWriteError(alias.Name))
                    {
                        continue;
                    }
                }

                // Set the alias in the specified scope or the
                // current scope.

                AliasInfo result = null;

                try
                {
                    if (string.IsNullOrEmpty(Scope))
                    {
                        result = SessionState.Internal.SetAliasItem(alias, Force, MyInvocation.CommandOrigin);
                    }
                    else
                    {
                        result = SessionState.Internal.SetAliasItemAtScope(alias, Scope, Force, MyInvocation.CommandOrigin);
                    }
                }
                catch (SessionStateException sessionStateException)
                {
                    WriteError(
                        new ErrorRecord(
                            sessionStateException.ErrorRecord,
                            sessionStateException));
                    continue;
                }
                catch (PSArgumentOutOfRangeException argOutOfRange)
                {
                    WriteError(
                        new ErrorRecord(
                            argOutOfRange.ErrorRecord,
                            argOutOfRange));
                    continue;
                }
                catch (PSArgumentException argException)
                {
                    WriteError(
                        new ErrorRecord(
                            argException.ErrorRecord,
                            argException));
                    continue;
                }

                // Write the alias to the pipeline if PassThru was specified

                if (PassThru && result != null)
                {
                    WriteObject(result);
                }
            }
        }

        private Dictionary<string, CommandTypes> _existingCommands;
        private Dictionary<string, CommandTypes> ExistingCommands
        {
            get
            {
                if (_existingCommands == null)
                {
                    _existingCommands = new Dictionary<string, CommandTypes>(StringComparer.OrdinalIgnoreCase);
                    CommandSearcher searcher = new CommandSearcher(
                        "*",
                        SearchResolutionOptions.CommandNameIsPattern | SearchResolutionOptions.ResolveAliasPatterns | SearchResolutionOptions.ResolveFunctionPatterns,
                        CommandTypes.All ^ CommandTypes.Alias,
                        this.Context);

                    foreach (CommandInfo commandInfo in searcher)
                    {
                        _existingCommands[commandInfo.Name] = commandInfo.CommandType;
                    }

                    // Also add commands from the analysis cache
                    foreach (CommandInfo commandInfo in System.Management.Automation.Internal.ModuleUtils.GetMatchingCommands("*", this.Context, this.MyInvocation.CommandOrigin))
                    {
                        if (!_existingCommands.ContainsKey(commandInfo.Name))
                        {
                            _existingCommands[commandInfo.Name] = commandInfo.CommandType;
                        }
                    }
                }

                return _existingCommands;
            }
        }

        private bool VerifyShadowingExistingCommandsAndWriteError(string aliasName)
        {
            CommandSearcher searcher = new CommandSearcher(aliasName, SearchResolutionOptions.None, CommandTypes.All ^ CommandTypes.Alias, this.Context);
            foreach (string expandedCommandName in searcher.ConstructSearchPatternsFromName(aliasName))
            {
                CommandTypes commandTypeOfExistingCommand;
                if (this.ExistingCommands.TryGetValue(expandedCommandName, out commandTypeOfExistingCommand))
                {
                    // Since the alias already exists, write an error.
                    SessionStateException aliasExists =
                        new SessionStateException(
                            aliasName,
                            SessionStateCategory.Alias,
                            "AliasAlreadyExists",
                            SessionStateStrings.AliasWithCommandNameAlreadyExists,
                            ErrorCategory.ResourceExists,
                            commandTypeOfExistingCommand);

                    WriteError(
                        new ErrorRecord(
                            aliasExists.ErrorRecord,
                            aliasExists));
                    return true;
                }
            }

            return false;
        }

        private Collection<AliasInfo> GetAliasesFromFile(bool isLiteralPath)
        {
            Collection<AliasInfo> result = new Collection<AliasInfo>();
            string filePath = null;
            using (StreamReader reader = OpenFile(out filePath, isLiteralPath))
            {
                long lineNumber = 0;
                string line = null;
                while ((line = reader.ReadLine()) != null)
                {
                    ++lineNumber;

                    if (LineShouldBeSkipped(line)) 
                    {
                        continue;
                    }

                    Collection<string> parsedLine = ParseCsvLine(line);

                    if (IsValidParsedLine(parsedLine, lineNumber, filePath)) 
                    {
                        ScopedItemOptions options = CreateItemOptions(parsedLine, filePath, lineNumber);
                        result.Add(ConstructAlias(parsedLine, options));
                    }
                }
            }

            return result;
        }

        private ScopedItemOptions CreateItemOptions(Collection<string> parsedLine, string filePath, long lineNumber) 
        {
            ScopedItemOptions options;
            if(!Enum.TryParse<ScopedItemOptions>(parsedLine[3], out options)){
                // if parsing is no succes
                string message = StringUtil.Format(AliasCommandStrings.ImportAliasOptionsError, filePath, lineNumber);
                ErrorRecord errorRecord =
                    new ErrorRecord(
                        new ArgumentException(),
                        "ImportAliasOptionsError",
                        ErrorCategory.ReadError,
                        filePath);

                errorRecord.ErrorDetails = new ErrorDetails(message);
                WriteError(errorRecord);
            }

            return options;
        }

        private AliasInfo ConstructAlias(Collection<string> parsedLine, ScopedItemOptions options) 
        {
            AliasInfo newAlias =
                        new AliasInfo(
                            parsedLine[0],
                            parsedLine[1],
                            Context,
                            options);
            string aliasDescription = parsedLine[2];
            if (!string.IsNullOrEmpty(aliasDescription))
            {
                newAlias.Description = aliasDescription;
            }

            return newAlias;
        }

        private bool IsValidParsedLine(Collection<string> parsedLine, long lineNumber, string filePath) 
        {
            if (parsedLine.Count != 4)
            {
                // if not four values, do ThrowTerminatingError(errorRecord) with ImportAliasFileFormatError, just like old implementation
                string message = StringUtil.Format(AliasCommandStrings.ImportAliasFileInvalidFormat, filePath, lineNumber);

                FormatException formatException =
                    new FormatException(message);

                ErrorRecord errorRecord =
                    new ErrorRecord(
                        formatException,
                        "ImportAliasFileFormatError",
                        ErrorCategory.ReadError,
                        filePath);

                errorRecord.ErrorDetails = new ErrorDetails(message);

                ThrowTerminatingError(errorRecord);
                return false;
            }

            return true;
        }

        private StreamReader OpenFile(out string filePath, bool isLiteralPath)
        {
            StreamReader result = null;
            filePath = null;
            ProviderInfo provider = null;
            Collection<string> paths = null;

            if (isLiteralPath)
            {
                paths = new Collection<string>();
                PSDriveInfo drive;
                paths.Add(SessionState.Path.GetUnresolvedProviderPathFromPSPath(this.Path, out provider, out drive));
            }
            else
            {
                // first resolve the path
                paths = SessionState.Path.GetResolvedProviderPathFromPSPath(this.Path, out provider);
            }

            // We can only export aliases to the file system
            if (!provider.NameEquals(this.Context.ProviderNames.FileSystem))
            {
                throw
                    PSTraceSource.NewNotSupportedException(
                        AliasCommandStrings.ImportAliasFromFileSystemOnly,
                        this.Path,
                        provider.FullName);
            }

            // We can only write to a single file at a time.
            if (paths.Count != 1)
            {
                throw
                    PSTraceSource.NewNotSupportedException(
                        AliasCommandStrings.ImportAliasPathResolvedToMultiple,
                        this.Path);
            }

            filePath = paths[0];

            try
            {
                FileStream file = new FileStream(filePath, FileMode.Open, FileAccess.Read, FileShare.Read);
                result = new StreamReader(file);
            }
            catch (IOException ioException)
            {
                ThrowFileOpenError(ioException, filePath);
            }
            catch (SecurityException securityException)
            {
                ThrowFileOpenError(securityException, filePath);
            }
            catch (UnauthorizedAccessException unauthorizedAccessException)
            {
                ThrowFileOpenError(unauthorizedAccessException, filePath);
            }

            return result;
        }

        private void ThrowFileOpenError(Exception e, string pathWithError)
        {
            string message =
                StringUtil.Format(AliasCommandStrings.ImportAliasFileOpenFailed, pathWithError, e.Message);

            ErrorRecord errorRecord = new ErrorRecord(
                e,
                "FileOpenFailure",
                ErrorCategory.OpenError,
                pathWithError);

            errorRecord.ErrorDetails = new ErrorDetails(message);
            this.ThrowTerminatingError(errorRecord);
        }
        #endregion Command code
    }
}
