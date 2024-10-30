
#!/bin/sh

# 检查参数
# 项目名称
NAME="$1"
# bundle identifier
BUNDLEID="$2"
# 创建的目录
DIR="$3"

if [ -z "$NAME" ]; then
    echo "工程名不能为空"
    exit 1
fi
if [ -z "$BUNDLEID" ]; then
    echo "bundleid不能为空"
    exit 1
fi

# 检查本地模块是否存在
if [ -d "./$NAME" ]; then
    echo "本地已经有了名为 $NAME 的模块，请换个名字再试试"
    exit 1
fi

echo "准备创建.xcodeproj文件..."

# 如果没有提供目录，使用当前目录
if [ -z "$DIR" ]; then
    DIR=$(pwd)
fi

# 调用 Ruby 脚本创建项目
ruby createProj.rb "$NAME" "$BUNDLEID" "$DIR"

# 复制模板
cp -r ./Template "$DIR"
# 修文件名类名
mv "$DIR/Template" "$DIR/$NAME"
mv "$DIR/$NAME/Template" "$DIR/$NAME/$NAME"

# 生成 Podfile 文件
echo "开始创建 PodSpec 文件..."
chmod 755 createPodfile.sh
./createPodfile.sh "$NAME" "$DIR"
echo "Podfile 创建完成"

# 更新 pod 依赖，执行 pod install
echo "pod install"
cd "$DIR/$NAME" || exit
pod install

