// 壁纸UI业务逻辑服务
import { WallpaperService, GeneratedWallpaper, WallpaperOperationResult } from './WallpaperService';
import componentSnapshot from '@ohos.arkui.componentSnapshot';
import fs from '@ohos.file.fs';
import image from '@ohos.multimedia.image';
import common from '@ohos.app.ability.common';
import photoAccessHelper from '@ohos.file.photoAccessHelper';
import { OperationResult, WallpaperApplyParams } from '../common/ServiceTypes';

export class WallpaperUIService {

  // 更新预览背景（返回新的背景色，不包含UI动画）
  async updatePreview(currentWallpaper: GeneratedWallpaper | null): Promise<string> {
    try {
      let newBackground = '#2c3e50';

      if (currentWallpaper) {
        const previewResult = WallpaperService.createWallpaperPreview(currentWallpaper);
        if (previewResult) {
          newBackground = previewResult;
        } else {
          newBackground = currentWallpaper.style.backgroundColor || '#2c3e50';
        }
      }

      console.log('Preview background calculated:', newBackground);
      return newBackground;
    } catch (error) {
      console.error('Failed to calculate preview background:', error);
      return '#2c3e50';
    }
  }

  // 更新当前页面的背景颜色（返回新的背景色，不包含UI动画）
  async updateBackgroundForCurrentPage(index: number, wallpaperList: (GeneratedWallpaper | null)[]): Promise<string> {
    try {
      let newBackground = '#2c3e50';

      if (wallpaperList.length > index && wallpaperList[index] !== null) {
        const wallpaper = wallpaperList[index];
        if (wallpaper) {
          const previewResult = WallpaperService.createWallpaperPreview(wallpaper);
          if (previewResult) {
            newBackground = previewResult;
          } else {
            newBackground = wallpaper.style.backgroundColor || '#2c3e50';
          }
        }
      }

      console.log('Background calculated for page:', index, newBackground);
      return newBackground;
    } catch (error) {
      console.error('Failed to calculate background for current page:', error);
      return '#2c3e50';
    }
  }

  // 应用壁纸选项（核心业务逻辑，不包含UI状态管理）
  async applyWallpaperOptions(params: WallpaperApplyParams): Promise<OperationResult> {
    if (!params.setLockScreen && !params.saveToGallery) {
      const result: OperationResult = { success: false, message: '未选择任何操作' };
      return result;
    }

    try {
      console.log('开始应用壁纸操作...');

      return new Promise((resolve) => {
        // 使用componentSnapshot API截图纯净壁纸区域
        componentSnapshot.get("pureWallpaperArea", async (error: Error, pixelMap: image.PixelMap) => {
          if (error) {
            console.error("截图失败: " + JSON.stringify(error));
            const result: OperationResult = { success: false, message: '截图失败' };
            resolve(result);
            return;
          }

          try {
            // 将PixelMap保存为JPEG格式
            const packOpts: image.PackingOption = {
              format: "image/jpeg",
              quality: 98
            };

            const imagePacker: image.ImagePacker = image.createImagePacker();
            const arrayBuffer: ArrayBuffer = await imagePacker.packing(pixelMap, packOpts);

            // 创建临时文件
            const filesDir: string = params.context.filesDir;
            const tempImagePath = `${filesDir}/temp_wallpaper_${Date.now()}.jpg`;

            // 保存临时文件
            const file = await fs.open(tempImagePath, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE);
            await fs.write(file.fd, arrayBuffer);
            await fs.close(file.fd);

            // 执行选定的操作
            const results = await WallpaperService.applyWallpaperOperations(
              tempImagePath,
              params.setLockScreen,
              params.saveToGallery
            );

            // 生成结果消息
            let message = '';
            if (params.setLockScreen && results.lockScreenSuccess) {
              message += '锁屏壁纸设置成功！';
            } else if (params.setLockScreen && !results.lockScreenSuccess) {
              message += '锁屏壁纸设置失败！';
            }

            if (params.saveToGallery && results.gallerySuccess) {
              if (message) message += '\n';
              message += '图片已保存到图库！';
            } else if (params.saveToGallery && !results.gallerySuccess) {
              if (message) message += '\n';
              message += '图片保存到图库失败！';
            }

            console.log('壁纸操作完成:', message);

            // 清理临时文件
            try {
              await fs.unlink(tempImagePath);
            } catch (unlinkError) {
              console.error('清理临时文件失败:', unlinkError);
            }

            // 释放资源
            imagePacker.release();
            pixelMap.release();

            const success = (params.setLockScreen ? results.lockScreenSuccess : true) &&
                           (params.saveToGallery ? results.gallerySuccess : true);

            const result: OperationResult = { success, message };
            resolve(result);

          } catch (packError) {
            console.error('图片处理失败:', packError);
            pixelMap.release();
            const result: OperationResult = { success: false, message: '图片处理失败' };
            resolve(result);
          }
        });
      });

    } catch (error) {
      console.error('应用壁纸失败:', error);
      const result: OperationResult = { success: false, message: '应用壁纸失败' };
      return result;
    }
  }

  // 保存图片到相册
  async saveImageToPhoto(buffer: ArrayBuffer, context: common.UIAbilityContext): Promise<OperationResult> {
    try {
      // 按照 _helper.txt 第86-94行的方法实现
      const helper = photoAccessHelper.getPhotoAccessHelper(context);
      const uri = await helper.createAsset(photoAccessHelper.PhotoType.IMAGE, 'jpg');
      const file = await fs.open(uri, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE);
      await fs.write(file.fd, buffer);
      await fs.close(file.fd);
      console.log("图片保存成功到相册:", uri);
      const result: OperationResult = { success: true, message: '图片保存成功' };
      return result;
    } catch (error) {
      console.error('保存图片到相册失败:', error);
      const result: OperationResult = { success: false, message: '保存图片失败' };
      return result;
    }
  }
}