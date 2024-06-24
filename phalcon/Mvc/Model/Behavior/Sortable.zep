
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
 * Class Sortable
 *
 * Allow models to have a automatic increase of sortable field
 *
 *```php
 *   $this->addBehavior(
 *       new Sortable([
 *           'beforeSave' => [
 *               'field'  => 'sortOrder',
 *           ],
 *       ])
 *   );
 *```
 *
 * @property array options
 * @package Phalcon\Mvc\Model\Behavior
 */
class Sortable extends Behavior
{
    const NAME = "sortable";

    /**
     * Listens for notifications from the models manager
     */
    public function notify(string! type, <ModelInterface> model)
    {
        var options, value, field, modelMetaData;

        /**
         * Check if the developer decided to take action here
         */
        if this->mustTakeAction(type) !== true {
            return null;
        }

        let options = this->getOptions(type);
        if typeof options != "array" {
            return;
        }

        /**
         * 'field' is the attribute to be updated instead of delete the record
         */
        if unlikely !fetch field, options["field"] {
            throw new Exception("The option 'field' is required");
        }

        /** @var MetaDataInterface $modelMetaData */
        let modelMetaData = model->getModelsMetaData();

        /**
         * Check if model has attribute
         */
        if unlikely !modelMetaData->hasAtribute(model, field) {
            throw new Exception("Model does not have attribute '" . field . "'");
        }

        /**
         * If the record field is already filled then skip
         */
        let value = model->readAttribute(field);
        if (value != null) || (value != "") {
            return;
        }

        /**
         * Find and calculate the current maximum value
         */
        let value = {model}::maximum(["column": field]);

        let value = value ? value + 1 : 1;
        model->writeAttribute(field, value);
    }
}
