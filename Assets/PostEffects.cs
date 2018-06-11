using System.Collections;
using System.Collections.Generic;
using UnityEngine;


// 自定义它作为后期效果的应用程序。 首先，我们将添加一行，以

// 防止我们将此脚本作为组件添加到不是相机的GameObject中
// 使脚本以编辑模式执行，否则在播放游戏的情况下预览更改会非常麻烦
[RequireComponent(typeof(Camera))]
[ExecuteInEditMode]
public class PostEffects : MonoBehaviour {

    // 添加成员，并增加一个get方法
    // 引用将要使用的图像效果着色器脚本，另外还需要动态创建一个材质
    public Shader curShader;
    private Material curMaterial;
 

    // 添加选项以便切换正在应用哪个图像效果传递，一个用于反转效果切换，另一个用于深度效果切换。
    // 在OnRenderImage中，我们将检查哪一个是相应的。 如果两者都打开，则反转效果。 如果没有，场景将不会有任何后期效果
    public bool InvertEffect;
    public bool DepthEffect;

    // 向成员添加另一个布尔值转化为线性空间
    public bool LinearInvertEffect;

    // 色调映射器音
    // 首先，我们需要添加一个新的布尔值，一个新的if语句和一个新的着色器通道。 我们还需要添加另一个属性，相机曝光
    public bool ToneMappingEffect;
    [Range(1.0f, 10.0f)]
    public float ToneMapperExposure = 2.0f;

    Material material
    {
        get
        {
            if (curMaterial == null)
            {
                curMaterial = new Material(curShader);
                curMaterial.hideFlags = HideFlags.HideAndDontSave;
            }
            return curMaterial;
        }
    }

    // 自动填充适当的着色器（通过名称查找它），确保在不支持图像效果或着色器不受支持的情况下脚本不会出错
    void Start()
    {
        curShader = Shader.Find("Hidden/PostEffects");
        GetComponent<Camera>().allowHDR = true;
        if (!SystemInfo.supportsImageEffects)
        {
            enabled = false;
            Debug.Log("not supported");
            return;
        }
        if (!curShader && !curShader.isSupported)
        {
            enabled = false;
            Debug.Log("not supported");
        }
        // 利用相机计算深度纹理。 深度纹理对许多效果很有用，比如景深。
        GetComponent<Camera>().depthTextureMode = DepthTextureMode.Depth;
    }

    // 在禁用Camera GameObject时销毁素材
    // 当你想在Update函数中更改图像效果着色器的值时，如果未启用摄像头，从Update函数提前返回
    void Update()
    {
        if (!GetComponent<Camera>().enabled)
            return;
    }
    void OnDisable()
    {
        if (curMaterial)
        {
            DestroyImmediate(curMaterial);
        }
    }

    // 为了应用我们的效果，我们需要另外一个函数OnRenderImage
    // 它需要两个参数，一个源RenderTexture和一个目标RenderTexture
    // 1、在RenderTexture中获取当前渲染场景，由sourceTexture完成
    // 2、使用Graphics.Blit将图像效果着色器应用到源纹理。 Blit意味着将所有像素从原点表面复制到目标表面，同时可以选择应用某种转换
    // 3、使用Graphics.Blit将图像效果着色器应用到目标RenderTexture。 如果该值为null，Blit将直接将结果发送到屏幕

    //  主纹理实际上是我们渲染的场景
    // 在OnRenderImage中应用此着色器并，我们已经有了源纹理和目标纹理（这是屏幕），所以只需要几行代码来应用效果
    void OnRenderImage(RenderTexture sourceTexture, RenderTexture destTexture)
    {
        // Graphics.Blit采用源纹理，目标纹理，包含着色器的材质以及使用哪个通道（从0开始）
        // 默认的后期效果会反转场景颜色
        if (curShader != null)
        {
            // 要申请的Pass已更改，因此您需要相应地更改Blit行。你在着色器中应用第二个Pass
            Graphics.Blit(sourceTexture, destTexture, material, 1);
            //Graphics.Blit(sourceTexture, destTexture, material, 0);
        }
        if (curShader != null)
        {
            // 检查打开的选项， 如果两者都打开则打开反转效果。 如果没有，场景将不会有任何后期效果
            if (InvertEffect)
            {
                Graphics.Blit(sourceTexture, destTexture, material, 0);
            }
            else if (DepthEffect)
            {
                Graphics.Blit(sourceTexture, destTexture, material, 1);
            }
            // 伽玛空间项目中线性空间中的效应计算：将另一个Pass添加到判断中，并向图像效果着色器添加另一个Pass
            else if (LinearInvertEffect)
            {
                Graphics.Blit(sourceTexture, destTexture, material, 2);
            }
            else if (ToneMappingEffect)
            {
                // 在声明之后，我们希望在效果处于活动状态时将值发送给着色器
                material.SetFloat("_ToneMapperExposure", ToneMapperExposure);
                Graphics.Blit(sourceTexture, destTexture, material, 3);
            }
            else
            {
                Graphics.Blit(sourceTexture, destTexture);
            }
        }
    }
}
