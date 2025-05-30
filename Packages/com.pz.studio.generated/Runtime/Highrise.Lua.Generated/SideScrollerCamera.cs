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
    [AddComponentMenu("Lua/SideScrollerCamera")]
    [LuaRegisterType(0x570572a7a0683513, typeof(LuaBehaviour))]
    public class SideScrollerCamera : LuaBehaviourThunk
    {
        private const string s_scriptGUID = "dcb0c85ded312444d85ab35cbc44e4f6";
        public override string ScriptGUID => s_scriptGUID;

        [Header("Zoom Settings")]
        [SerializeField] public System.Boolean m_canZoom = true;
        [SerializeField] public System.Double m_zoom = 10;
        [SerializeField] public System.Double m_zoomMin = 5;
        [SerializeField] public System.Double m_zoomMax = 15;
        [SerializeField] public System.Boolean m_camerFollowPlayer = true;
        [SerializeField] public System.Double m_cameraFollowSpeed = 3;
        [SerializeField] public System.Double m_xOffset = 0;
        [SerializeField] public System.Double m_yOffset = 5;
        [SerializeField] public System.Boolean m_canPan = true;
        [SerializeField] public System.Double m_mobileZoomSensitivity = 1;
        [SerializeField] public System.Boolean m_boundary = false;
        [SerializeField] public System.Double m_minBoundaryX = -10;
        [SerializeField] public System.Double m_maxBoundaryX = 10;
        [SerializeField] public System.Double m_minBoundaryY = -10;
        [SerializeField] public System.Double m_maxBoundaryY = 10;
        [SerializeField] public System.Boolean m_deadzone = true;
        [SerializeField] public System.Double m_deadzoneWidth = 3;
        [SerializeField] public System.Double m_deadzoneHeight = 3;

        protected override SerializedPropertyValue[] SerializeProperties()
        {
            if (_script == null)
                return Array.Empty<SerializedPropertyValue>();

            return new SerializedPropertyValue[]
            {
                CreateSerializedProperty(_script.GetPropertyAt(0), m_canZoom),
                CreateSerializedProperty(_script.GetPropertyAt(1), m_zoom),
                CreateSerializedProperty(_script.GetPropertyAt(2), m_zoomMin),
                CreateSerializedProperty(_script.GetPropertyAt(3), m_zoomMax),
                CreateSerializedProperty(_script.GetPropertyAt(4), m_camerFollowPlayer),
                CreateSerializedProperty(_script.GetPropertyAt(5), m_cameraFollowSpeed),
                CreateSerializedProperty(_script.GetPropertyAt(6), m_xOffset),
                CreateSerializedProperty(_script.GetPropertyAt(7), m_yOffset),
                CreateSerializedProperty(_script.GetPropertyAt(8), m_canPan),
                CreateSerializedProperty(_script.GetPropertyAt(9), m_mobileZoomSensitivity),
                CreateSerializedProperty(_script.GetPropertyAt(10), m_boundary),
                CreateSerializedProperty(_script.GetPropertyAt(11), m_minBoundaryX),
                CreateSerializedProperty(_script.GetPropertyAt(12), m_maxBoundaryX),
                CreateSerializedProperty(_script.GetPropertyAt(13), m_minBoundaryY),
                CreateSerializedProperty(_script.GetPropertyAt(14), m_maxBoundaryY),
                CreateSerializedProperty(_script.GetPropertyAt(15), m_deadzone),
                CreateSerializedProperty(_script.GetPropertyAt(16), m_deadzoneWidth),
                CreateSerializedProperty(_script.GetPropertyAt(17), m_deadzoneHeight),
            };
        }
        
#if HR_STUDIO
        [MenuItem("CONTEXT/SideScrollerCamera/Edit Script")]
        private static void EditScript()
        {
            VisualStudioCodeOpener.OpenPath(AssetDatabase.GUIDToAssetPath(s_scriptGUID));
        }
#endif
    }
}

#endif
