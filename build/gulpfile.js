var gulp = require('gulp'),
    cleancss = require('gulp-clean-css'),
    concat = require('gulp-concat'),
    uglify = require('gulp-uglify'),
    rename = require('gulp-rename'),
    jshint = require('gulp-jshint');

//语法检查
gulp.task('jshint', function() {
    return gulp.src('/root/Chart.js-2.7.1/dist/Chart.bundle.js')
        .pipe(jshint({asi: true}))
        .pipe(jshint.reporter('default'));
});
//压缩css
gulp.task('cleancss', function() {
    return gulp.src('./src/css/*.css') //需要操作的文件
        .pipe(rename({ suffix: '.min' })) //rename压缩后的文件名
        .pipe(cleancss()) //执行压缩
        .pipe(gulp.dest('dist/css')); //输出文件夹
});
//压缩，合并 js
gulp.task('minifyjs', function() {
    return gulp.src('/root/Chart.js-2.7.1/dist/Chart.bundle.js', { base: '/root/Chart.js-2.7.1'}) //需要操作的文件
        //.pipe(concat('main.js')) //合并所有js到main.js
        .pipe(uglify()) //压缩
        //.pipe(rename({ suffix: '.min' })) //rename压缩后的文件名
        .pipe(gulp.dest('chg/build/', {cwd: '/root/Chart.js-2.7.1/aaa/', mode: '0644'})); //输出到文件夹
});

//默认命令，在cmd中输入gulp后，执行的就是这个任务(压缩js需要在检查js之后操作)
gulp.task('default', ['jshint'], function() {
    gulp.start('cleancss', 'minifyjs');　　
});
