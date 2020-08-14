/* ****************************************************************************
 *
 * Copyright (c) Microsoft Corporation.
 *
 * This source code is subject to terms and conditions of the Apache License, Version 2.0. A
 * copy of the license can be found in the License.html file at the root of this distribution. If
 * you cannot locate the Apache License, Version 2.0, please send an email to
 * dlr@microsoft.com. By using this source code in any fashion, you are agreeing to be bound
 * by the terms of the Apache License, Version 2.0.
 *
 * You must not remove this notice, or any other, from this software.
 *
 *
 * ***************************************************************************/

using System.Collections.Generic;

namespace System.Management.Automation.Interpreter
{
    internal interface IInstructionProvider
    {
        void AddInstructions(LightCompiler compiler);
    }

    internal abstract class Instruction
    {
        internal const int UnknownInstrIndex = int.MaxValue;

        internal virtual int ConsumedStack { get { return 0; } }

        internal virtual int ProducedStack { get { return 0; } }

        internal virtual int ConsumedContinuations { get { return 0; } }

        internal virtual int ProducedContinuations { get { return 0; } }

        internal int StackBalance
        {
            get { return ProducedStack - ConsumedStack; }
        }

        internal int ContinuationsBalance
        {
            get { return ProducedContinuations - ConsumedContinuations; }
        }

        internal abstract int Run(InterpretedFrame frame);

        internal virtual string InstructionName
        {
            get { return GetType().Name.Replace("Instruction", string.Empty); }
        }

        public override string ToString()
        {
            return InstructionName + "()";
        }

        internal virtual string ToDebugString(int instructionIndex, object cookie, Func<int, int> labelIndexer, IList<object> objects)
        {
            return ToString();
        }

        internal virtual object GetDebugCookie(LightCompiler compiler)
        {
            return null;
        }
    }

    internal sealed class NotInstruction : Instruction
    {
        internal static readonly Instruction Instance = new NotInstruction();

        private NotInstruction() { }

        public override int ConsumedStack { get { return 1; } }

        public override int ProducedStack { get { return 1; } }

        public override int Run(InterpretedFrame frame)
        {
            frame.Push((bool)frame.Pop() ? ScriptingRuntimeHelpers.False : ScriptingRuntimeHelpers.True);
            return +1;
        }
    }
}
