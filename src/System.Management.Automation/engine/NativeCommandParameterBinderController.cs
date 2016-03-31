/********************************************************************++
Copyright (c) Microsoft Corporation.  All rights reserved.
--********************************************************************/

using System.Collections.ObjectModel;

namespace System.Management.Automation
{
    /// <summary>
    /// This is the interface between the NativeCommandProcessor and the
    /// parameter binders required to bind parameters to a native command.
    /// </summary>
    /// 
    internal class NativeCommandParameterBinderController : ParameterBinderController
    {
        #region ctor

        /// <summary>
        /// Initializes the cmdlet parameter binder controller for
        /// the specified native command and engine context
        /// </summary>
        /// 
        /// <param name="command">
        /// The command that the parameters will be bound to.
        /// </param>
        /// 
        internal NativeCommandParameterBinderController(NativeCommand command)
            : base(command.MyInvocation, command.Context, new NativeCommandParameterBinder(command))
        {
        }

        #endregion ctor

        /// <summary>
        /// Gets the command arguments in string form
        /// </summary>
        ///
        internal String Arguments
        {
            get
            {
                return ((NativeCommandParameterBinder)DefaultParameterBinder).Arguments;
            }
        } // Arguments

        /// <summary>
        /// Passes the binding directly through to the parameter binder.
        /// It does no verification against metadata.
        /// </summary>
        /// 
        /// <param name="argument">
        /// The name and value of the variable to bind.
        /// </param>
        /// 
        /// <param name="flags">
        /// Ignored.
        /// </param>
        /// 
        /// <returns>
        /// True if the parameter was successfully bound. Any error condition
        /// produces an exception.
        /// </returns>
        /// 
        internal override bool BindParameter(
            CommandParameterInternal argument,
            ParameterBindingFlags flags)
        {
            Diagnostics.Assert(false, "Unreachable code");

            throw new InvalidOperationException();
        }

        /// <summary>
        /// Binds the specified parameters to the native command
        /// </summary>
        /// 
        /// <param name="parameters">
        /// The parameters to bind.
        /// </param>
        /// 
        /// <remarks>
        /// For any parameters that do not have a name, they are added to the command
        /// line arguments for the command
        /// </remarks>
        /// 
        internal override Collection<CommandParameterInternal> BindParameters(Collection<CommandParameterInternal> parameters)
        {
            ((NativeCommandParameterBinder)DefaultParameterBinder).BindParameters(parameters);

            Diagnostics.Assert(emptyReturnCollection.Count == 0, "This list shouldn't be used for anything as it's shared.");

            return emptyReturnCollection;
        } // BindParameters

        static readonly Collection<CommandParameterInternal> emptyReturnCollection = new Collection<CommandParameterInternal>(); 
    }

}


