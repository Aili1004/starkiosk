package com.snepo.givv.cardbrowser.util
{
    import flash.external.ExternalInterface;
    import flash.utils.getQualifiedClassName;

    /**
     * <p>Dataの中身を解析するクラス。perlのData::Dumperを参考にした。
     * 現在対応しているのは、Object, Array, Number, String, Booleanのみ。
     * XMLに関してはできるようにするつもり。
     * 特徴としてはFireBugのconsoleに出力する機能をデフォルトでサポートしている。
     * debug, info, warn, error の出力形式をサポートしている。</p>
     * <listing>
     * package {
     *    import org.libspark.utils.Dumper;
     *    public Class Hoge {
     *        var test:Object = { a:'hoge', b:'fuga'};
     *        Dumper.debug(test);
     *        trace(Dumper.toString(test));
     *    }
     *    // output
     *         $var0 = {
     *                     'a' => 'hoge', 
     *                     'b' => 'fuga', 
     *                 } 
     *     
     * }</listing>
     * @author dealforest
     */

    public class Dumper {
        private static const INDENT:String = "    ";
        /*
         * @default 4tab
         */
        private static var _dumpString:String = "";

        /**
         * 解析結果を文字列として返すことができます
         *
         * @param args 解析したい要素(引数全て)
         * @return _txt フォーマットに合わせた解析した文字列
         */
        public static function toString(... args):String {
            var _txt:String = _dumpString = '';
            for (var a:String in args)
                _txt += parse(args[a]);
            return _txt;
        }

        /**
         * FireBugのコンソールに'debug'として表示
         *
         * @param args 解析したい要素(引数全て)
         */
        public static function debug(... args):void {
            var _txt:String = _dumpString = '';
            for (var a:String in args)
                _txt += parse(args[a]);
            ExternalInterface.call('console.debug', _txt);
        }

        /**
         * FireBugのコンソールに'info'として表示
         *
         * @param args 解析したい要素(引数全て)
         */
        public static function info(... args):void {
            var _txt:String = _dumpString = '';
            for (var a:String in args)
                _txt += parse(args[a]);
            ExternalInterface.call('console.info', _txt);
        }

        /**
         * FireBugのコンソールに'warn'として表示
         *
         * @param args 解析したい要素(引数全て)
         */
        public static function warn(... args):void {
            var _txt:String = _dumpString = '';
            for (var a:String in args)
                _txt += parse(args[a]);
            ExternalInterface.call('console.warn', _txt);
        }

        /**
         * FireBugのコンソールに'error'として表示
         *
         * @param arg 解析したい要素(引数全て)
         */
        public static function error(... args):void {
            var _txt:String = _dumpString = '';
            for (var a:String in args)
                _txt += parse(args[a]);
            ExternalInterface.call('console.error', _txt);
        }

        /**
         * 要素の数だけ繰り返す。大元みたいなもん。
         *
         * @param arg 解析したい要素(引数のうちの１つ)
         * @return 各要素単位の解析した文字列
         * @private
         */
        public static function parse(arg:*):String {
            var argIndent:String = ('$var'+ ' = ');
            _dumpString += argIndent;
            inspect(arg, argIndent.replace(/./g, ' '));
            _dumpString += '\n';
            return _dumpString;
        }
       
        /**
         * 再帰処理の前のイニシャライズみたいなもん。
         *
         * @param arg 解析したい要素(引数のうちの１つ)
         * @param indent 表示する際の空白
         * @private
         */
        private static function inspect(arg:*, indent:String):void {
            var bracket:Object;

            switch (getQualifiedClassName(arg)) {
                case 'Object':
                    bracket = {start: '{', end: '}'};
                case 'Array':
                    bracket ||= {start: '[', end: ']'};
                    _dumpString += bracket.start + '\n';
                    recursion(arg, indent + INDENT);
                    _dumpString += (indent +bracket.end);
                    break;
                default:
                    _dumpString += format(arg, indent, true);
            }
        }
            
        /**
         * 再帰で何度もこいつが呼び出される。
         *
         * @param arg 解析したい要素(引数のうちの１つ)
         * @param indent 表示する際の空白
         * @private
         */
        private static function recursion(arg:*, indent:String):void {
            for (var index:String in arg) {
                var tmp:* = arg[index];
                var className:String = getQualifiedClassName(tmp);
                var bracket:Object;

                switch(className) {
                    case 'Object':
                        bracket = {start: '{', end: '}'};
                    case 'Array':
                        bracket ||= {start: '[', end: ']'};
                        var str:String = (getQualifiedClassName(arg) == 'Object')
                            ? '\'' + index + '\' => ' : '';
                        var indent_str:String = str.replace(/./g, ' ');

                        _dumpString += (indent + str + bracket.start + "\n");
                        recursion(tmp, indent + indent_str + INDENT);
                        _dumpString += (indent + indent_str + bracket.end + ",");
                        break;
                    default:
                        _dumpString += format(tmp, indent, false, arg, index);
                }
                _dumpString += "\n";
            }
        }

        /**
         * 表示するフォーマットを整形している。
         *
         * @param target 表示対象のObject
         * @param indent 表示する際の空白
         * @param braket ,を表示するかしないか
         * @param parent 一階層上のObject
         * @param index Objectのkey
         * @return フォーマットに整形された文字列
         * @private
         */
        private static function format(target:Object, indent:String, bracket:Boolean, parent:* = null, index:String = null):String {
            var className:String = getQualifiedClassName(target);
            var str:String = "";

            if (getQualifiedClassName(parent) == 'Object')
                return indent +  "\'" + index + "\'" + " => " + target + (bracket ? '' : ',');

            switch (className) {
                case 'String':
                    return (bracket) 
                        ? "\'" + target + "\'"
                        : indent + "\'" + target + "\',";

                case 'Array':
                case 'int':
                case 'uint':
                case 'Number':
                case 'Boolean':
                    return (bracket) 
                        ? target.toString()
                        : indent + target.toString() + ",";
                default:
                    return 'don\'t analyze';
            }
        }
    }
}
