/*

    Copyright (c) 2025 Pocketz World. All rights reserved.

    This is a generated file, do not edit!

    Generated by com.pz.studio
*/

#if UNITY_EDITOR

using System;
using System.Linq;
using UnityEngine;
using Highrise.Client;
using Highrise.Studio;
using Highrise.Lua;
using UnityEditor;

namespace Highrise.Lua.Generated
{
    [AddComponentMenu("Lua/MoveObject")]
    [LuaRegisterType(0x48569c9123c0e923, typeof(LuaBehaviour))]
    public class MoveObject : LuaBehaviourThunk
    {
        private const string s_scriptGUID = "35090c3f5eb1fc14394a702ff242851b";
        public override string ScriptGUID => s_scriptGUID;

        [Tooltip("The object to move. If left empty, the object this script is attached to will be moved.")]
        [SerializeField] public UnityEngine.Transform _objectToMove = default;
        [Tooltip("The starting point of the move. If left empty, the object will start at its current position.")]
        [SerializeField] public System.Collections.Generic.List<UnityEngine.Transform> _travelPoints = default;
        [Tooltip("The duration of the move in seconds between each point.")]
        [SerializeField] public System.Double _durationInSeconds = 3;
        [SerializeField] public System.Boolean _faceMoveDirection = true;
        [Tooltip("If true, the move will move back to the first point after reaching the last point.")]
        [SerializeField] public System.Boolean _wrapBackToStart = true;
        [Tooltip("If true, the move will start over at the first point once it reaches the end.")]
        [SerializeField] public System.Boolean _loop = true;
        [Tooltip("If true, the move will move backwards through the points after reaching the end point")]
        [SerializeField] public System.Boolean _reverseAfterReachEnd = true;
        [Tooltip("If true, the move will slow down when starting and arriving at each point.")]
        [SerializeField] public System.Boolean _smoothMove = true;

        protected override SerializedPropertyValue[] SerializeProperties()
        {
            if (_script == null)
                return Array.Empty<SerializedPropertyValue>();

            return new SerializedPropertyValue[]
            {
                CreateSerializedProperty(_script.GetPropertyAt(0), _objectToMove),
                CreateSerializedProperty(_script.GetPropertyAt(1), _travelPoints),
                CreateSerializedProperty(_script.GetPropertyAt(2), _durationInSeconds),
                CreateSerializedProperty(_script.GetPropertyAt(3), _faceMoveDirection),
                CreateSerializedProperty(_script.GetPropertyAt(4), _wrapBackToStart),
                CreateSerializedProperty(_script.GetPropertyAt(5), _loop),
                CreateSerializedProperty(_script.GetPropertyAt(6), _reverseAfterReachEnd),
                CreateSerializedProperty(_script.GetPropertyAt(7), _smoothMove),
            };
        }
        
#if HR_STUDIO
        [MenuItem("CONTEXT/MoveObject/Edit Script")]
        private static void EditScript()
        {
            VisualStudioCodeOpener.OpenPath(AssetDatabase.GUIDToAssetPath(s_scriptGUID));
        }
#endif
    }
}

#endif
