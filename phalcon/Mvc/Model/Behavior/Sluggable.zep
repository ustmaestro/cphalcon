
/**
 * This file is part of the Phalcon Framework.
 *
 * (c) Phalcon Team <team@phalcon.io>
 *
 * For the full copyright and license information, please view the LICENSE.txt
 * file that was distributed with this source code.
 */

namespace Phalcon\Mvc\Model\Behavior;

use Phalcon\Mvc\ModelInterface;
use Phalcon\Mvc\Model\Behavior;
use Phalcon\Mvc\Model\Exception;
use Phalcon\Mvc\Model\MetaDataInterface;

/**
 * Class Sluggable
 *
 * Allow models to have automatic fill of attribute with a slug value from another attribute
 *
 *```php
 *   $this->addBehavior(
 *       new Sluggable([
 *           'beforeSave' => [
 *               'field'  => 'title',
 *               'slugField'  => 'slug',
 *               'immutable'  => true,
 *               'lowercase'  => true,
 *               'separator'  => '-',
 *               'transliterator' => 'Any-Latin; Latin-ASCII',
 *           ],
 *       ])
 *   );
 *```
 *
 * @property array options
 * @package Phalcon\Mvc\Model\Behavior
 */
class Sluggable extends Behavior
{
    const NAME = "sluggable";
    const DEFAULT_TRANSLITERATOR = "Any-Latin; Latin-ASCII";
    const TRANSLITERATION_MAP = [
        "À": "A", "Á": "A", "Â": "A", "Ã": "A", "Ä": "A", "Å": "A", "Æ": "AE", "Ç": "C",
        "È": "E", "É": "E", "Ê": "E", "Ë": "E", "Ì": "I", "Í": "I", "Î": "I", "Ï": "I",
        "Ð": "D", "Ñ": "N", "Ò": "O", "Ó": "O", "Ô": "O", "Õ": "O", "Ö": "O", "Ő": "O",
        "Ø": "O", "Ù": "U", "Ú": "U", "Û": "U", "Ü": "U", "Ű": "U", "Ý": "Y", "Þ": "TH",
        "ß": "ss",
        "à": "a", "á": "a", "â": "a", "ã": "a", "ä": "a", "å": "a", "æ": "ae", "ç": "c",
        "è": "e", "é": "e", "ê": "e", "ë": "e", "ì": "i", "í": "i", "î": "i", "ï": "i",
        "ð": "d", "ñ": "n", "ò": "o", "ó": "o", "ô": "o", "õ": "o", "ö": "o", "ő": "o",
        "ø": "o", "ù": "u", "ú": "u", "û": "u", "ü": "u", "ű": "u", "ý": "y", "þ": "th",
        "ÿ": "y"
    ];

    /**
     * Listens for notifications from the models manager
     * @return void
     * @throws Exception
     */
    public function notify(string! type, <ModelInterface> model) -> void
    {
        var options, field, value, slugField, slugValue, modelMetaData,
            immutable, lowercase, separator, transliterator;

        if this->mustTakeAction(type) !== true {
            return;
        }

        let options = this->getOptions(type);
        if typeof options != "array" {
            return;
        }

        if unlikely !fetch field, options["field"] {
            throw new Exception("The option 'field' is required");
        }

        if unlikely !fetch field, options["slugField"] {
            throw new Exception("The option 'slugField' is required");
        }

        /** @var MetaDataInterface $modelMetaData */
        let modelMetaData = model->getModelsMetaData();

        if unlikely !modelMetaData->hasAtribute(model, field) {
            throw new Exception("Model does not have attribute '" . field . "'");
        }

        if unlikely !modelMetaData->hasAtribute(model, slugField) {
            throw new Exception("Model does not have attribute '" . slugField . "'");
        }

        if !fetch immutable, options["immutable"] {
            let immutable = false;
        }

        if !fetch lowercase, options["lowercase"] {
            let lowercase = true;
        }

        if !fetch separator, options["separator"] {
            let separator = "-";
        }

        if !fetch transliterator, options["transliterator"] {
            let transliterator = self::DEFAULT_TRANSLITERATOR;
        }

        let slugValue = model->readAttribute(slugField);
        if (!empty slugValue) && immutable {
            return;
        }

        let value = model->readAttribute(field);
        let slugValue = $this->getSlug(value, lowercase, separator, transliterator);

        model->writeAttribute(slugField, slugValue);
    }

    /**
     * Transliterate a text to slug
     * @return string
     */
    public function getSlug(
        string text = "",
        bool lowercase = true,
        string separator = "-",
        string transliterator = self::DEFAULT_TRANSLITERATOR
    ) -> string {
        var parts, replacedParts;

        if empty text {
            return "";
        }

        if separator !== "" {
            let parts = explode(separator, this->transliterate(text, transliterator));
        } else {
            let parts = [this->transliterate(text, transliterator)];
        }

        let replacedParts = array_map(
            function (element) use (separator) {
                let element = preg_replace("/[^a-zA-Z0-9=\s—–-]+/u", "", element);
                return preg_replace("/[=\s—–-]+/u", separator, element);
            },
            parts
        );

        let text = trim(implode(separator, replacedParts), separator);

        if separator !== "" {
            let text = preg_replace("#" . preg_quote(separator) . "+#", separator, text);
        }

        return lowercase ? strtolower(text) : text;
    }

    /**
     * Transliterate text
     * @return string
     */
    public function transliterate(string text, string transliterator) -> string
    {
        if this->hasIntl() {
            return transliterator_transliterate(transliterator, text);
        }

        return strtr(text, self::TRANSLITERATION_MAP);
    }

    /**
     * Check if intl extension is loaded
     * @return bool
     */
    public function hasIntl() -> bool
    {
        return extension_loaded("intl");
    }
}
